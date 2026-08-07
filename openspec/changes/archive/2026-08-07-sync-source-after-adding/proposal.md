## Why

Al agregar una fuente exitosamente, la app vuelve a la lista de fuentes sin sincronizar nada — si el usuario entra al detalle de esa fuente, ve la pantalla vacía ("Sin publicaciones") aunque la fuente sí tenga artículos publicados, porque nadie disparó el fetch de feeds del lado del servidor para ella. El usuario tiene que saber que existe pull-to-refresh en el Inbox y esperar a que ese sync general la alcance, lo cual no es obvio ni inmediato — la primera impresión de una fuente recién agregada es la de una fuente vacía o rota.

## What Changes

- Tras agregar una fuente exitosamente, navegar directamente a la pantalla de detalle de esa fuente (`/sources/:id`) en vez de solo volver a la lista de fuentes.
- Al entrar a esa pantalla en este flujo puntual (recién agregada), disparar automáticamente una sincronización de feeds antes de mostrar los artículos, mostrando el indicador de carga ya existente mientras dura.
- Reusar el trigger de sincronización de cuenta completa (`FeedSyncTrigger`) en vez de construir un mecanismo de sync por fuente individual — el servidor ya prioriza las fuentes nunca sincronizadas (`last_synced_at` nulo primero), así que la fuente recién agregada queda cubierta por ese mismo fetch sin necesidad de un parámetro nuevo.
- Errores de esa sincronización se manejan en silencio (sin mensaje de error visible), igual que el refresco silencioso ya existente tras el login — la fuente ya fue validada al agregarla, así que un fallo acá es una falla de red transitoria, no una señal de que la fuente esté mal.
- La navegación a la pantalla de fuentes desde el flujo de "agregar" sigue recargando su lista como hoy (comportamiento ya normado), simplemente además continúa hacia el detalle de la fuente nueva.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `source-management`: se agrega el comportamiento de navegación post-agregado (ir al detalle de la fuente en vez de solo la lista) y la sincronización automática al entrar a ese detalle en ese flujo puntual.
- `feed-polling`: se agrega un tercer disparador válido del fetch on-demand (además de pull-to-refresh y login): agregar una fuente exitosamente.

## Impact

- `lib/features/sources/presentation/screens/add_source_screen.dart`: en `AddSourceSuccess`, hacer `Navigator.pop(state.source)` en vez de `Navigator.pop(true)`.
- `lib/features/sources/presentation/screens/sources_screen.dart`: el FAB pasa a esperar `NewsSource?` (en vez de `bool?`) del push a `/sources/add`; si vuelve una fuente, recarga la lista (como hoy) y además navega a `/sources/${source.id}?justAdded=true`.
- `lib/presentation/app/router.dart`: la ruta `/sources/:id` lee el query param `justAdded` y lo pasa como flag a `SourceDetailScreen`; inyecta `FeedSyncTrigger` y `SyncUserData` (ya registrados en `injection.dart`) al construir la pantalla.
- `lib/features/sources/presentation/screens/source_detail_screen.dart`: nuevo parámetro `syncOnOpen`; si es `true`, dispara el nuevo método de sync-y-carga del cubit en vez de la carga simple.
- `lib/features/sources/presentation/cubit/source_detail_cubit.dart`: nuevo método (ej. `syncAndLoadArticles`) que dispara `FeedSyncTrigger.execute()` (silenciando errores), luego `SyncUserData.execute()`, y recién ahí recarga vía `GetSourceArticles`; reusa el estado `SourceDetailLoading` existente para el indicador de carga, sin agregar un estado nuevo.
- Tests unitarios y de widget de `source_detail_cubit`, `sources_screen`, `add_source_screen` a extender.
- No hay cambios de servidor ni de Edge Function.
