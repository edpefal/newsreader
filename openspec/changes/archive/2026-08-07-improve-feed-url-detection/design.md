## Context

`FeedUrlResolver` (`lib/core/feed/feed_url_resolver.dart`) hoy expone `candidatesFor(rawUrl) → List<String>`, consumido secuencialmente por `AddSource._resolveFeed` (`lib/features/sources/domain/usecases/add_source.dart`) con un `for` + `try/catch(ParseException) { continue }`: prueba cada candidato en orden, se queda con el primero que parsee como feed válido, y cualquier excepción que no sea `ParseException` (típicamente red/timeout) se propaga de inmediato sin probar el resto.

Ver `proposal.md` para la motivación y `specs/feed-url-discovery/spec.md` para el contrato de comportamiento completo.

## Goals / Non-Goals

**Goals:**
- Ampliar la cobertura de detección automática a dominio propio para Substack y Ghost, y agregar Medium.
- Paralelizar la etapa de candidatos heurísticos por velocidad, sin sacrificar determinismo.
- Evitar requests especulativos innecesarios cuando la URL ingresada ya es el feed exacto.

**Non-Goals:**
- No se agrega soporte a más plataformas allá de Substack, Ghost, WordPress y Medium (Beehiiv se deja explícitamente sin heurística, como ya estaba).
- No se cambia el mecanismo de fallback (email-to-RSS) ni su UI más allá de que sigue disparándose cuando la detección falla.
- No se introduce un timeout configurable nuevo por candidato — se usa el mismo `HttpClient` y su comportamiento de timeout actual, sin cambiarlo.

## Decisions

### 1. Candidatos genéricos reemplazan la tabla `_platformSuffixes` por subdominio

En vez de `{'substack.com': '/feed', 'wordpress.com': '/feed/', 'ghost.io': '/rss/'}` condicionada a que el host termine en ese subdominio, se prueba una lista fija de sufijos sobre el origin del host ingresado, sin condición de plataforma: `/feed`, `/feed/`, `/rss/`, `/atom.xml`. Esto cubre Substack y Ghost en dominio propio (que hoy no detecta) y WordPress self-hosted, sin necesidad de mantener una tabla de subdominios que en la práctica es minoritaria frente a dominio propio.

**Alternativa considerada:** mantener la tabla por subdominio y agregarle además un intento genérico como candidato de respaldo final. Se descarta porque duplicaría trabajo (el sufijo de la tabla ya está incluido en la lista genérica) sin aportar precisión adicional — no hay ninguna plataforma soportada hoy cuyo sufijo de feed dependa de estar en su subdominio propio en vez de en dominio custom.

### 2. Los casos de inserción de path siguen siendo específicos de plataforma

Substack `@usuario` (existente) y Medium `@usuario` / publicación (nuevo) no pueden resolverse con un sufijo genérico porque el feed no cuelga de la raíz del dominio ingresado sino que hay que insertar `/feed` en medio del path o cambiar de subdominio. Estos siguen siendo reglas explícitas por host (`substack.com`, `medium.com`), evaluadas antes que los sufijos genéricos.

### 3. Resolución en dos etapas: solitario, luego ráfaga paralela con prioridad determinista

Etapa 1 prueba solo `rawUrl`. Etapa 2 (si la 1 falla) dispara todos los candidatos aplicables a la vez, pero el ganador se decide recorriendo la lista de candidatos **en orden de prioridad** (inserción de plataforma primero, sufijos genéricos después) y tomando el primero cuyo resultado, una vez resuelto, sea válido — no el primero en llegar. Concretamente: se lanzan todos los `Future`s de la etapa 2 al mismo tiempo, y se van *awaiteando* en el orden de la lista de prioridad (el primer `await` de la lista bloquea solo hasta que ESE candidato en particular resuelva, pero como todos ya están en vuelo, no hay costo adicional de latencia por hacerlo en orden).

**Alternativa considerada (carrera pura, gana el primero en responder):** se descartó en la exploración con el usuario por introducir no-determinismo — el mismo input podría resolver a un feed distinto según el timing de red de cada corrida, lo cual además complica los tests (dejarían de ser deterministas sin simular condiciones de carrera).

### 4. Etapa 2 solo se dispara si la etapa 1 falla (no siempre-paralelo-desde-el-inicio)

Se descartó lanzar los ~6 candidatos siempre en paralelo desde el arranque (más simple de implementar) porque, cuando el usuario ya pegó la URL exacta del feed (el caso más común para usuarios que copian la URL desde su lector de RSS o desde la propia plataforma), dispararía 5-6 requests especulativos innecesarios contra el servidor del usuario — carga extra evitable y potencialmente indistinguible de un scan a ojos del hosting de destino.

### 5. Manejo de errores de red en la etapa 2

Como todos los candidatos de la etapa 2 están en vuelo simultáneamente, un error de red en uno de ellos ya no puede abortar "antes de que se prueben los demás" (ya se están probando). El nuevo comportamiento es: se espera el resultado de todos los candidatos en vuelo (éxito, fallo de parseo, o error de red) y se decide con la información completa — si al menos uno resultó válido, gana el de mayor prioridad entre los válidos; si ninguno resultó válido (sea por parseo o por red), se lanza `FeedDiscoveryException` igual que hoy. Esto es un cambio de comportamiento respecto al `spec.md` original (que documentaba "un error de red aborta sin probar más candidatos" para *todos* los candidatos) pero preserva ese comportamiento para la etapa 1 (URL ingresada tal cual), que sigue siendo un intento aislado y secuencial respecto a la etapa 2.

### 6. Nuevo estado de UI para la etapa 2

Se agrega `AddSourceValidatingHeuristics` (nombre tentativo) junto al `AddSourceValidating` existente en `add_source_state.dart`, emitido por `AddSourceCubit` cuando `AddSource` pasa de la etapa 1 a la etapa 2. `add_source_screen.dart` muestra "Buscando en varios lugares posibles..." para ese estado en vez del spinner genérico actual. Esto requiere que `AddSource.execute` (o `_resolveFeed`) exponga de alguna forma la transición de etapa al Cubit — por ejemplo mediante un callback opcional o dividiendo `_resolveFeed` en dos métodos que el Cubit orqueste, a definir en tasks.md sin comprometer la forma exacta aquí.

## Risks / Trade-offs

- **[Riesgo] Falsos positivos de sufijos genéricos**: un dominio no-blog podría casualmente tener un endpoint válido en `/feed` que no sea el newsletter/blog que el usuario esperaba (ej. un feed de comentarios, o un feed no relacionado). → Mitigación: se sigue validando que el contenido parsee como RSS/Atom (`FeedParser.parse`) antes de aceptar el candidato; el riesgo de que exista un feed *parseable* pero irrelevante en esa ruta específica es bajo y ya existía en menor medida con la tabla actual.
- **[Riesgo] Más requests salientes por fuente agregada cuando la URL exacta no fue pegada**: hasta 6 requests en paralelo en la etapa 2 en vez de hasta 2 secuenciales hoy. → Mitigación: solo ocurre cuando la etapa 1 (intento único) falló, y de todas formas hoy esos casos ya fallaban silenciosamente para varias plataformas (Substack/Ghost en dominio propio, Medium) — el costo de red adicional se paga solo en el camino que hoy termina en fallback de email de todas formas.
- **[Trade-off] Cambio de comportamiento en manejo de errores de red no cubierto por el spec original**: documentado explícitamente como requirement MODIFIED en la delta spec para que quede trazable, no es un efecto secundario silencioso.

