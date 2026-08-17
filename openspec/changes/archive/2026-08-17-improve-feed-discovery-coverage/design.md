## Context

Ver `proposal.md` para la motivación (caso concreto: `https://androidweekly.net/`). Datos relevantes reproducidos durante la investigación, contra el sitio real:

- El feed vive en `/rss.xml` (200, XML válido, parseable con `webfeed_plus`), que no está en `FeedUrlResolver._genericSuffixes`.
- `/rss/` (que sí está en la lista) responde `200` con `curl` (Accept: `*/*` por default) pero `406 Not Acceptable` con `package:http` de Dart (que no manda ningún header `Accept`) — confirmado reproduciendo la llamada exacta con ambos clientes.
- El sitio no declara `<link rel="alternate">` en su `<head>`, así que el auto-descubrimiento tampoco lo hubiera encontrado en este caso puntual — pero el cambio de prioridad (etapa 3 → candidato de la ráfaga paralela) sigue siendo una mejora de cobertura general para otros sitios que sí lo declaran.
- `AddSource._resolveFeed` ya tiene la estructura de tres etapas descrita en `feed-url-discovery`; este change no cambia la etapa 1 (URL tal cual, secuencial) ni el manejo de errores de red (aborta en etapa 1, se ignoran en etapa 2).
- `HttpClient.get` (interfaz en `core/network/`) hoy no acepta ni manda headers custom — solo `post` los acepta.

## Goals / Non-Goals

**Goals:**
- Ampliar la cobertura de sitios detectables sin agregar heurísticas de alto riesgo de falso positivo (scraping de `<a href>`, casos de plataforma adicionales) — eso quedó fuera de alcance explícitamente.
- Resolver la causa raíz general (headers de descubrimiento + lista de sufijos incompleta), no solo parchar `androidweekly.net` puntualmente.

**Non-Goals:**
- No se agregan casos de plataforma específicos nuevos (WordPress, Blogger, YouTube, Reddit, Tumblr, GitHub, Discourse, Squarespace) — quedó fuera del alcance elegido ("cobertura amplia", no "máxima").
- No se agrega escaneo de `<a href>` en el body como fallback adicional — mismo motivo.
- No se agrega soporte para JSON Feed — requeriría un parser nuevo, fuera de alcance de este change.
- No se cambia el comportamiento de `import_opml.dart` más allá de heredar el header `Accept` por compartir `HttpClient` — no hay heurísticas de descubrimiento ahí, solo se trae el contenido de una URL ya conocida.

## Decisions

### 1. `Accept: */*` hardcodeado en `HttpPackageClient.get`, sin tocar la interfaz `HttpClient`
Se descarta extender `HttpClient.get` con un parámetro `headers` (como ya tiene `post`) porque no hace falta variar el header caso a caso — `*/*` es un default seguro y universal para cualquier request GET de este cliente (mismo comportamiento que `curl` sin flags). Los dos únicos consumidores de `.get()` (`AddSource`, `import_opml`) se benefician igual, sin necesitar saber nada del header. Si en el futuro aparece un caso que necesite un `Accept` distinto, ahí sí se justifica extender la interfaz — no antes (YAGNI).

### 2. El candidato de `<link rel="alternate">` se mueve a la ráfaga paralela, no a un "stage 3.5" nuevo
En vez de mantenerlo como paso secuencial post-etapa-2 (como hoy), `AddSource._resolveFeed` extrae el link del HTML de la etapa 1 (si la etapa 1 falló como feed) **antes** de lanzar `Future.wait` sobre los candidatos heurísticos, y lo antepone a esa lista con la prioridad más alta. Esto no agrega ningún request de red nuevo (el HTML ya está en memoria) y solo cambia cuándo se evalúa: en paralelo con todo lo demás en vez de después. Resultado: mismo o menor tiempo total de detección (mejor caso: si el link declarado es válido, ya no hay que esperar a que fallen todos los sufijos genéricos primero), y prioridad más alta refleja que es la señal más confiable (el sitio la declara, no es una adivinanza).

### 3. Lista de sufijos genéricos: agregar solo `/rss.xml`, `/feed.xml`, `/index.xml`
Se evaluaron variantes más agresivas (`/feed/atom`, `/rss.php`, `/index.rss`, `.rss`) pero se descartaron por ahora — los tres agregados cubren las convenciones más comunes fuera de las ya soportadas (confirmado con el caso real de AndroidWeekly) sin inflar demasiado el número de requests en paralelo por candidato (de 4 a 7 sufijos × 2 variantes de host = 14 requests, sigue siendo razonable).

## Risks / Trade-offs

- **[Riesgo] Mandar `Accept: */*` no soluciona servidores que exigen exactamente `application/rss+xml` o similar y rechazan `*/*`** → Aceptado: no se encontró ningún caso real así durante la investigación (el propio `/rss/` de AndroidWeekly rechazó `application/rss+xml` explícito pero aceptó `*/*`, que es el comportamiento más común). Si aparece un caso real, es un fix puntual futuro.
- **[Riesgo] Más sufijos genéricos = más requests en paralelo por intento de agregar fuente** → Mitigación: siguen siendo todos concurrentes (no seriales), y el timeout por request (`AppConstants.feedFetchTimeout`, 10s) no cambia — el tiempo total percibido no debería crecer de forma perceptible.
- **[Trade-off] No cubre sitios sin `<link rel="alternate">`, sin sufijo genérico conocido y sin caso de plataforma reconocido** (ninguna heurística es exhaustiva) → Aceptado, coherente con el alcance "amplio, no máximo" elegido; el mensaje de error ya sugiere pegar la URL exacta del feed como último recurso.

## Migration Plan

Cambio de código puro, sin datos ni infraestructura externa involucrada. Se implementa y se corre `flutter test` + `flutter analyze`; no requiere pasos de despliegue especiales (se libera con el próximo build de la app). Sin plan de rollback especial más allá de revertir el commit si algo se rompe.
