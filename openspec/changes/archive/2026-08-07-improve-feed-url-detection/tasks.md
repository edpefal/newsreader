## 1. `FeedUrlResolver`: candidatos genéricos + inserción de Medium

- [x] 1.1 Reemplazar `_platformSuffixes` (mapa por subdominio) por una lista fija de sufijos genéricos (`/feed`, `/feed/`, `/rss/`, `/atom.xml`) aplicados sobre el origin del host ingresado, sin condicionar a que el host matchee un subdominio de plataforma.
- [x] 1.2 Agregar detección de perfil/publicación de Medium (`medium.com/@usuario`, `usuario.medium.com`, `medium.com/<slug>`) con inserción de `/feed` inmediatamente después del host, siguiendo el mismo patrón que el caso existente de perfil de Substack.
- [x] 1.3 Definir el orden de prioridad de la lista de candidatos que devuelve el resolver: `rawUrl` primero (sin cambios), luego casos de inserción de plataforma (Substack, Medium), luego sufijos genéricos — el orden de la lista es lo que después usa `AddSource` para determinismo en la etapa 2.
- [x] 1.4 Actualizar `test/unit/core/feed/feed_url_resolver_test.dart`: quitar/ajustar tests que dependían de la tabla por subdominio (`*.substack.com`, `*.wordpress.com`, `*.ghost.io`), agregar casos de dominio propio para Substack y Ghost, agregar casos de Medium (perfil, subdominio propio, publicación), y confirmar que Beehiiv sigue sin generar candidato de inserción específico.
- [x] 1.5 (hallado en verificación manual) Normalizar la URL agregando `https://` cuando el usuario no incluye esquema, antes de derivar cualquier candidato — sin esto, `Uri.parse` en `HttpPackageClient` produce una URI sin host y lanza un `ArgumentError` no capturado (`AddSourceError('Ocurrió un error inesperado.')` genérico en vez de detección real). Agregar tests en `feed_url_resolver_test.dart` para el caso sin esquema.

## 2. `AddSource`: resolución escalonada en paralelo con prioridad determinista

- [x] 2.1 Separar `_resolveFeed` en etapa 1 (probar `rawUrl` en solitario) y etapa 2 (candidatos heurísticos restantes), preservando que un error de red en la etapa 1 siga abortando de inmediato sin pasar a la etapa 2.
- [x] 2.2 Implementar la etapa 2 disparando todos los candidatos heurísticos aplicables de forma concurrente (`Future.wait` sobre resultados capturados, no excepciones sin capturar) y seleccionando el ganador recorriendo la lista en el orden de prioridad definido en la tarea 1.3, tomando el primero cuyo resultado ya resuelto sea válido.
- [x] 2.3 Ajustar el manejo de errores de la etapa 2 para que un error de red en un candidato individual no aborte la evaluación de los demás candidatos en vuelo — solo se lanza `FeedDiscoveryException` si ninguno de los candidatos de la etapa 2 resultó válido (ni por parseo ni por red).
- [x] 2.4 Exponer de alguna forma la transición de etapa 1 → etapa 2 hacia el caller (`AddSourceCubit`), para que la UI pueda reflejar el cambio de estado — definir la forma concreta (callback, stream, o valor de retorno intermedio) al implementar, sin cambiar la firma pública de `AddSource.execute`.
- [x] 2.5 Actualizar `test/unit/features/sources/domain/usecases/add_source_test.dart`: casos de dominio propio para Substack/Ghost, Medium, un test que verifique prioridad determinista cuando un candidato de menor prioridad resuelve más rápido que uno de mayor prioridad, y un test que verifique que un error de red en un candidato de la etapa 2 no aborta si otro candidato en la misma ráfaga es válido.

## 3. UI: estado intermedio "Buscando en varios lugares posibles..."

- [x] 3.1 Agregar el nuevo estado (p. ej. `AddSourceValidatingHeuristics`) en `add_source_state.dart`, extendiendo `Equatable` como el resto de los estados.
- [x] 3.2 Emitir el nuevo estado desde `AddSourceCubit.addSource` cuando `AddSource` señala la transición a la etapa 2 (usando el mecanismo definido en la tarea 2.4).
- [x] 3.3 Mostrar "Buscando en varios lugares posibles..." en `add_source_screen.dart` para el nuevo estado, distinto del spinner/label ya usado para `AddSourceValidating`.
- [x] 3.4 Actualizar `test/unit/features/sources/presentation/cubit/add_source_cubit_test.dart` y `test/widget/features/sources/add_source_screen_test.dart` para cubrir la transición de estados y el nuevo texto en pantalla.

## 4. Verificación

- [x] 4.1 Correr `flutter analyze` sin warnings nuevos.
- [x] 4.2 Correr `flutter test test/unit/core/feed/ test/unit/features/sources/ test/widget/features/sources/` y confirmar que todo pasa.
- [x] 4.3 Probar manualmente en la app: agregar una fuente con URL de dominio propio de Substack/Ghost (ej. un blog real conocido), una URL de Medium con `@usuario`, y una URL que no resuelva a ningún feed (confirmar que sigue cayendo al fallback de generar email).
