## Why

`FeedUrlResolver` detecta la plataforma por sufijo de subdominio (`*.substack.com`, `*.wordpress.com`, `*.ghost.io`) y solo entonces prueba el sufijo de feed correspondiente. En la práctica esto falla en el caso más común: publicaciones de Substack y Ghost alojadas en dominio propio (no en el subdominio de la plataforma), que son mayoría entre blogs "serios" (ej. `stratechery.com/feed`, `platformer.news/feed` funcionan aunque ninguno vive en `*.substack.com`). Medium tampoco está soportado hoy. El resultado es que un usuario que pega la URL humana de un blog real de una plataforma que Reevo sí soporta conceptualmente termina, la mayoría de las veces, cayendo al fallback de generar un email — cuando el blog sí tenía un feed RSS descubrible.

## What Changes

- Reemplazar la lista de sufijos por-plataforma-de-subdominio por una lista de sufijos **genéricos** que se prueban sobre el dominio raíz sin importar la plataforma detectada: `/feed`, `/feed/`, `/rss/`, `/atom.xml`.
- Agregar Medium como plataforma reconocida para el caso de **inserción de path** (perfil `medium.com/@usuario` y publicación `medium.com/<slug>`), análogo al caso ya existente de perfil de Substack (`substack.com/@usuario`).
- Cambiar la resolución de candidatos de **secuencial** a **escalonada en dos etapas**:
  - Etapa 1: probar la URL ingresada tal cual, en solitario (se preserva el comportamiento actual de "pegar la URL exacta del feed").
  - Etapa 2 (solo si la etapa 1 no resultó en un feed válido): disparar todos los candidatos restantes (casos de inserción de plataforma + sufijos genéricos) **en paralelo**, resolviendo de forma **determinista** por orden de prioridad de la lista — no gana el candidato que responda primero por timing de red, gana el primero válido según el orden de prioridad, aunque todos se hayan disparado a la vez.
- **BREAKING** (comportamiento, no API pública): un error de red en un candidato individual de la etapa 2 ya no aborta inmediatamente la detección completa — se espera el resultado del resto de candidatos en vuelo antes de decidir éxito o fallo, porque todos ya se dispararon en paralelo. Un error de red en la etapa 1 (URL ingresada tal cual) sigue abortando de inmediato, sin pasar a la etapa 2.
- Agregar un estado de UI intermedio ("Buscando en varios lugares posibles...") distinto al spinner genérico actual, visible durante la etapa 2, para que el usuario entienda que se están probando varias URLs candidatas.
- Normalizar la URL ingresada agregándole el esquema `https://` cuando el usuario no lo incluye (ej. `stratechery.com` en vez de `https://stratechery.com`) — hallado durante la verificación manual: sin esto, `Uri.parse` en el cliente HTTP produce una URI sin host y lanza un `ArgumentError` no capturado que termina mostrando "Ocurrió un error inesperado" en vez de intentar la detección. Es el caso más común de lo que un usuario realmente escribe a mano.

## Capabilities

### New Capabilities

(ninguna — esta change modifica una capability existente)

### Modified Capabilities

- `feed-url-discovery`: la estrategia de generación de candidatos pasa de "sufijo fijo por subdominio de plataforma reconocida" a "sufijos genéricos sobre el dominio raíz + casos de inserción de path específicos por plataforma (Substack, Medium)"; la resolución pasa de secuencial a escalonada-paralela con prioridad determinista; el manejo de errores de red durante la etapa de candidatos heurísticos cambia (ya no aborta al primer error, espera el resto de la ráfaga en paralelo).

## Impact

- `lib/core/feed/feed_url_resolver.dart`: rediseño del generador de candidatos (sufijos genéricos + inserción de path para Substack y Medium) + normalización de esquema faltante antes de derivar cualquier candidato.
- `lib/features/sources/domain/usecases/add_source.dart`: el método `_resolveFeed` pasa de un `for` secuencial con `continue` a una resolución en dos etapas, con la etapa 2 en paralelo (`Future.wait` o equivalente) y selección determinista por prioridad.
- `lib/features/sources/presentation/cubit/add_source_cubit.dart` y `add_source_state.dart`: nuevo estado intermedio para la etapa 2.
- `lib/features/sources/presentation/screens/add_source_screen.dart`: mostrar el mensaje "Buscando en varios lugares posibles..." para el nuevo estado.
- `test/unit/core/...`: tests existentes de `FeedUrlResolver` y `AddSource` a actualizar (los que dependían de la lista de sufijos por subdominio) y extender (casos de dominio propio, Medium, paralelismo con prioridad determinista).
- No afecta el flujo de email-to-RSS más allá de seguir siendo el mismo fallback cuando todos los candidatos fallan. No se agrega ningún tipo de fuente nuevo ni se generaliza el producto más allá de RSS/Atom.
