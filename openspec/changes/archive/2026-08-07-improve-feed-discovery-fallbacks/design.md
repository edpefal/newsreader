## Context

Ver `proposal.md` para la motivación y los sitios reales que expusieron el gap. Estado actual relevante:

- `FeedUrlResolver.candidatesFor(rawUrl)` (`lib/core/feed/feed_url_resolver.dart`) es una función **pura y síncrona**: deriva candidatos por patrón de URL únicamente (normalización de esquema, casos de inserción de Substack/Medium, sufijos genéricos sobre el host tal cual), sin hacer ninguna solicitud de red.
- `AddSource._resolveFeed` (`lib/features/sources/domain/usecases/add_source.dart`) resuelve en dos etapas: etapa 1 prueba `candidates.first` (la URL normalizada) en solitario; etapa 2 dispara el resto de `candidatesFor()` en paralelo, con prioridad determinista por orden de lista.
- `_tryCandidate(candidate)` hace `_httpClient.get(candidate)` y descarta el body si `_feedParser.parse()` lanza `ParseException` — hoy no hay forma de recuperar ese HTML después.
- `package:html` (parser HTML del Dart team) ya es dependencia transitiva vía `flutter_widget_from_html` — está en `pubspec.lock`, no hace falta agregar peso nuevo al bundle.

## Goals / Non-Goals

**Goals:**
- Cubrir `notboring.co` (fallback `www.`) y `simonwillison.net` (auto-descubrimiento por `<link rel="alternate">`) sin regresar en velocidad para el caso común (Substack/Ghost/WordPress/Medium en dominio propio, que ya funcionan).
- No disparar solicitudes de red adicionales para el auto-descubrimiento cuando no hace falta — reusar el HTML de la etapa 1.

**Non-Goals:**
- No se reemplaza la lista de sufijos genéricos por auto-descubrimiento universal (sería un cambio mucho más grande, con más requests por intento, y los sufijos genéricos siguen siendo más baratos para el caso común).
- No se intenta auto-descubrimiento sobre el HTML de los candidatos de la etapa 2 (solo sobre el de la etapa 1) — mantiene el alcance acotado a un único HTML ya en memoria, sin sumar complejidad de "cuál candidato de la etapa 2 usar como fuente del HTML".
- No se resuelve ningún otro patrón de redirección de dominio más allá de `www.` (ej. dominios que redirigen a un subdominio arbitrario tipo `blog.midominio.com`) — fuera de alcance, no evidenciado por los sitios probados.

## Decisions

### 1. `www.<host>` como candidatos adicionales de menor prioridad dentro de `FeedUrlResolver`

Mismo mecanismo ya existente (síncrono, por patrón de URL), sin tocar el contrato de `candidatesFor()`. Se agregan después de los sufijos genéricos sobre el host original, así que quedan en la etapa 2 (paralelo) igual que el resto, sin necesidad de una etapa nueva ni cambios en `AddSource`.

**Alternativa considerada:** seguir redirects HTTP automáticamente en el `HttpClient` y confiar en que `notboring.co/feed` redirija a `www.notboring.co/feed`. Se descarta porque el problema real es que el dominio apex **no redirige** rutas que no sean la raíz (`/feed` devuelve 404 directo, no un 301) — no hay redirect que seguir, hay que generar el candidato explícitamente.

### 2. Auto-descubrimiento por `<link rel="alternate">` como etapa 3, solo si 1 y 2 fallan, reusando el HTML de la etapa 1

Requiere I/O (o al menos, contenido ya bajado) y parseo de HTML — una clase de operación distinta a los candidatos por patrón de URL, así que no encaja en la función pura de `FeedUrlResolver`. Se modela como un paso adicional orquestado por `AddSource`, después de que la etapa 2 falla:

1. `_tryCandidate` para la etapa 1 se modifica para, en caso de `ParseException`, retener el HTML descargado (no solo descartarlo) en el resultado.
2. Si la etapa 2 también falla, `AddSource` pasa ese HTML retenido a una función pura nueva `HtmlFeedLinkExtractor.extract(html, baseUri)` que devuelve la URL de feed declarada (o `null`).
3. Si devuelve una URL, se prueba como un candidato final más (mismo mecanismo de `_tryCandidate`).

**Por qué reusar el HTML de la etapa 1 y no volver a pedirlo:** la etapa 1 ya hizo un GET a la URL que el usuario ingresó — normalmente la home o un artículo del sitio, que suele tener el mismo `<head>` templatizado en todas las páginas. Pedirlo de nuevo sería una solicitud redundante contra el mismo sitio.

**Alternativa considerada:** hacer auto-descubrimiento sobre CADA candidato de la etapa 2 que devuelva HTML (no feed). Se descarta por complejidad y costo: multiplicaría los requests (fetch candidato + fetch de su link declarado, por cada candidato de la etapa 2) para un beneficio marginal — el HTML de la etapa 1 (URL que el usuario efectivamente pegó) es, en la enorme mayoría de los casos, suficiente.

**Alternativa considerada:** usar `package:html` para todo el DOM vs. una extracción con regex acotada al `<head>`. Se opta por `package:html` porque ya es dependencia transitiva (sin costo real de bundle) y es mucho más tolerante a variaciones de orden de atributos, comillas, y mayúsculas/minúsculas que una regex — evita falsos negativos frágiles.

### 3. Sin estado de UI nuevo para la etapa 3

La etapa 3 solo se alcanza cuando la etapa 2 (que ya muestra "Buscando en varios lugares posibles...") terminó sin éxito. Agregar un tercer mensaje distinto para una etapa que en la práctica agrega, como mucho, una request más y unos milisegundos, no se justifica — se mantiene el mismo estado `AddSourceValidatingHeuristics` cubriendo toda la fase heurística (etapas 2 y 3 combinadas desde la perspectiva de la UI).

## Risks / Trade-offs

- **[Riesgo] `<link rel="alternate">` engañoso o roto** → Mitigación: el candidato extraído se valida igual que cualquier otro (debe parsear como feed RSS/Atom real vía `FeedParser`); si el sitio declara un link roto o no-feed, simplemente no pasa la validación y se cae al mensaje de error existente, mismo comportamiento que cualquier candidato inválido hoy.
- **[Riesgo] Sitios con múltiples `<link rel="alternate">` (ej. RSS y Atom a la vez, o varios feeds temáticos)** → Se toma el primero que matchee `application/rss+xml` o `application/atom+xml`, en orden de aparición en el HTML. No se intenta elegir "el mejor" — igual de razonable que cualquier otro criterio determinista, y cubre el caso común de un solo feed principal declarado.
- **[Trade-off] Costo de parsear HTML con `package:html` en el flujo de agregar fuente** → Aceptado: solo ocurre en el peor caso (etapas 1 y 2 ya fallaron), no en el camino feliz que cubre la mayoría de las plataformas soportadas.
