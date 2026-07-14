## Context

Hoy `AddSource.execute(feedUrl)` (`lib/features/sources/domain/usecases/add_source.dart`) asume que el string recibido ya es la URL exacta del feed: chequea duplicado, hace `HttpClient.get`, y parsea el body con `FeedParser.parse`. `HttpPackageClient.get` (`lib/core/network/http_package_client.dart`) no chequea status code — un 404 devuelve igual el body (típicamente HTML de error), que `WebfeedFeedParser` no logra parsear como RSS ni Atom y termina lanzando `ParseException`. Esto es relevante porque significa que "probar una URL candidata" y "ver si falla" ya tiene una señal clara y reusable: `ParseException` = no era un feed válido; `NetworkException`/`TimeoutException` = problema de conectividad, no de la URL en sí.

`AddSourceScreen`/`AddSourceCubit` ya manejan errores genéricos vía `AppException.message` mostrado en un SnackBar (`lib/features/sources/presentation/screens/add_source_screen.dart`), así que no hace falta tocar ese mecanismo — solo agregar un nuevo tipo de excepción con su mensaje.

## Goals / Non-Goals

**Goals:**
- Permitir pegar la URL "humana" de un newsletter (home o artículo puntual) en Substack, WordPress.com o Ghost Pro, y resolver automáticamente la feed URL real.
- Preservar 100% el comportamiento actual para quien pega la URL exacta del feed (cero regresión).
- Mantener la lógica de detección como código puro, testeable sin red ni mocks de HTTP.
- Dar un mensaje de error claro y accionable cuando la detección no es posible.

**Non-Goals:**
- Autodiscovery genérico vía HTML (`<link rel="alternate">`) — cubriría dominios propios, pero se descarta para v1 por el request/parseo HTML adicional que implica.
- Fuerza bruta de rutas comunes (`/rss`, `/feed.xml`, etc.) como último recurso.
- Soporte para Medium (requiere transformar el path `/@usuario` o `/publicación`, no encaja en la regla única "origin + sufijo fijo").
- Soporte para dominios propios/custom domains de las plataformas cubiertas (indetectables solo por hostname).
- Soporte para Beehiiv: se evaluó y se descartó (ver Decisión 1) porque no tiene una ruta de feed fija.

## Decisions

### 1. Nueva clase pura `FeedUrlResolver` en `lib/core/feed/`
Vive junto a `FeedParser`/`FeedData` porque es lógica de dominio sobre feeds, no está atada a ninguna librería de terceros (solo usa `Uri` de `dart:core`), y no requiere abstracción per las reglas de CLAUDE.md (no envuelve infraestructura externa).

API:
```dart
class FeedUrlResolver {
  /// Devuelve la lista ordenada de candidatos de feed URL a probar:
  /// [rawUrl] siempre primero (preserva el comportamiento actual),
  /// seguido del candidato heurístico si el host matchea una plataforma conocida.
  List<String> candidatesFor(String rawUrl);
}
```

Reglas por plataforma (todas origin + sufijo fijo, sin tocar el path):

| Plataforma | Patrón de host | Sufijo |
|---|---|---|
| Substack | `*.substack.com` | `/feed` |
| WordPress.com | `*.wordpress.com` | `/feed/` |
| Ghost Pro | `*.ghost.io` | `/rss/` |

Verificado manualmente contra un sitio real de cada plataforma (`ederperez.substack.com/feed`, `theconversation.wordpress.com/feed/`, `demo.ghost.io/rss/`): las tres devuelven `200` con `content-type` de RSS/Atom válido.

**Beehiiv quedó fuera de esta tabla.** Se investigó y se verificó contra una publicación real (`newsletterexamples.beehiiv.com/feed`) que devuelve el HTML del sitio, no un feed. Según la [documentación de Beehiiv](https://www.beehiiv.com/support/article/9363537272215-how-to-add-your-beehiiv-newsletter-to-a-website-using-rss), el feed no vive en una ruta fija: cada publicación debe generarlo manualmente desde su panel (Configuración → RSS) y obtiene una URL única terminada en `.xml`, no predecible por patrón de host. No existe heurística de URL posible para esta plataforma sin un paso adicional (p. ej. scrapear el HTML en busca de un link, lo cual ya es autodiscovery, descartado para v1).

Si el host no matchea ninguna de las plataformas soportadas, `candidatesFor` devuelve solo `[rawUrl]` (comportamiento actual sin cambios).

**Caso especial: perfil de Substack sin subdominio.** Substack también permite compartir perfiles como `https://substack.com/@usuario` (el usuario va en el path, no en el subdominio). Este formato se detecta por separado (host `substack.com`/`www.substack.com` + primer segmento de path con prefijo `@`) y se transforma directamente a `https://usuario.substack.com/feed`. A diferencia de Medium, se decidió sí cubrir este caso porque es un único formato adicional y bien acotado (un solo prefijo `@` a extraer), no una familia de casos con múltiples formas de URL como en Medium (perfil vs. publicación vs. dominio propio).

Alternativa considerada: resolver e intentar candidatos dentro del propio `AddSource`, sin clase separada. Se descarta porque mezclaría lógica pura de matching de URLs con I/O (fetch), dificultando testear los patrones de plataforma de forma aislada y rápida.

### 2. Orquestación del loop de candidatos en `AddSource.execute`
```
para cada candidato en FeedUrlResolver.candidatesFor(input):
    intentar HttpClient.get(candidato) + FeedParser.parse(...)
    si tiene éxito → resuelto, salir del loop con (candidato, feedData)
    si NetworkException o TimeoutException → propagar inmediatamente, abortar loop
    si ParseException → continuar con el siguiente candidato
si el loop termina sin éxito → throw FeedDiscoveryException
```
Solo después de tener un candidato resuelto exitosamente se llama a `sourceRepository.sourceExists(feedUrlResuelta)` y se construye el `NewsSource`.

Alternativa considerada: mantener el chequeo de duplicado sobre el input crudo, antes del loop. Se descarta porque el input crudo puede no ser la feedUrl real que terminará guardada (p. ej. usuario pega la home de un Substack ya agregado, pero lo que está guardado es `.../feed`); chequear ahí daría falsos negativos de duplicado.

### 3. Nueva excepción `FeedDiscoveryException`
Sigue el patrón `sealed class AppException` existente en `lib/core/errors/app_exception.dart`:
```dart
class FeedDiscoveryException extends AppException {
  const FeedDiscoveryException([
    super.message = 'No pudimos detectar el feed automáticamente. '
        'Pega la URL exacta del feed RSS (por ejemplo, que termine en /feed o .xml).',
  ]);
}
```
Se usa un único mensaje genérico independientemente de si la causa fue "plataforma no reconocida" o "plataforma reconocida pero el candidato tampoco parseó" — ambos casos piden la misma acción al usuario, y distinguir mensajes no aporta valor proporcional a la complejidad de mantener dos textos y su cobertura de tests.

### 4. Copy de `AddSourceScreen`
- Texto explicativo: "Pega el link de tu newsletter (o la URL del feed RSS si la tienes)."
- Hint del campo: `https://autor.substack.com`

## Risks / Trade-offs

- **[Riesgo] Más requests de red en el caso de éxito por heurística**: pegar una URL humana implica al menos 2 fetches (el original que falla, luego el candidato). → Mitigación: aceptable dado que solo ocurre en el flujo de "agregar fuente", que no es de alta frecuencia ni sensible a latencia; el timeout por intento sigue siendo el mismo (`AppConstants.feedFetchTimeout`, 10s).
- **[Riesgo] Cambio de comportamiento en detección de duplicados**: un usuario que reintente agregar una fuente ya existente pegando la URL humana (en vez de la feed URL exacta) ya no recibe el error de duplicado instantáneamente, sino después del round-trip de detección. → Mitigación: documentado explícitamente en el proposal como cambio de comportamiento esperado; el resultado final (rechazo por duplicado) es el mismo, solo cambia la latencia.
- **[Riesgo] Cobertura limitada de plataformas**: dominios propios, Medium y Beehiiv quedan fuera de v1. → Mitigación: el mensaje de `FeedDiscoveryException` guía al usuario a la vía manual (pegar el feed exacto), que sigue funcionando igual que hoy.
- **[Riesgo] Falsos positivos de patrón de host**: improbable pero posible que un dominio no relacionado use `*.substack.com` como subdominio propio sin ser realmente un newsletter Substack. → Mitigación: no aplica en la práctica, `*.substack.com` es un dominio controlado por Substack.

## Migration Plan

No aplica migración de datos (no hay cambios de esquema Hive ni de API pública). El cambio es aditivo a nivel de código y solo afecta el flujo interactivo de `AddSourceScreen`. Deploy estándar vía release de la app; no requiere pasos de rollback especiales más allá de revertir el commit.

## Open Questions

Ninguna pendiente — decisiones de scope y UX ya confirmadas en la sesión de exploración previa.
