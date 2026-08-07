## 1. `SourceDetailCubit`: sync-y-carga tras agregar

- [x] 1.1 Agregar `FeedSyncTrigger` y `SyncUserData` como dependencias del constructor de `SourceDetailCubit`.
- [x] 1.2 Agregar el método `syncAndLoadArticles(String sourceId)`: emite `SourceDetailLoading`, llama `SyncUserData.execute()` (sube la fuente recién agregada, que solo existe en Hive local hasta ese momento), llama `FeedSyncTrigger.execute()` silenciando cualquier excepción (try/catch vacío con comentario, mismo criterio que `InboxCubit._silentFeedRefresh()`), llama `SyncUserData.execute()` de nuevo (baja los artículos nuevos), y recién ahí llama `GetSourceArticles.execute(sourceId)` para emitir `SourceDetailLoaded`. **Corregido tras prueba manual**: la primera versión omitía el `SyncUserData.execute()` inicial y el fetch corría sin que el servidor conociera la fuente nueva — ver `design.md`, Decisión 2.
- [x] 1.3 Actualizar `test/unit/features/sources/presentation/cubit/source_detail_cubit_test.dart`: agregar mocks de `FeedSyncTrigger`/`SyncUserData`, tests para `syncAndLoadArticles` (camino feliz, y caso donde `FeedSyncTrigger.execute()` lanza excepción pero igual se llega a `SourceDetailLoaded` con lo que haya local).

## 2. `SourceDetailScreen`: flag `syncOnOpen`

- [x] 2.1 Agregar parámetro `syncOnOpen` (`bool`, default `false`) al constructor de `SourceDetailScreen`, y los parámetros necesarios para construir el `SourceDetailCubit` con sus nuevas dependencias.
- [x] 2.2 En el `build()`, si `syncOnOpen` es `true`, llamar `cubit.syncAndLoadArticles(source.id)` en vez de `cubit.loadArticles(source.id)`.
- [x] 2.3 Actualizar `test/widget/features/sources/source_detail_screen_test.dart` para cubrir ambos casos (`syncOnOpen: true` dispara sync-y-carga, `syncOnOpen: false`/default dispara solo carga).

## 3. Routing: query param `justAdded`

- [x] 3.1 En `lib/presentation/app/router.dart`, en la ruta `/sources/:id`, leer `state.uri.queryParameters['justAdded'] == 'true'` y pasarlo como `syncOnOpen` a `SourceDetailScreen`; inyectar `getIt<FeedSyncTrigger>()` y `getIt<SyncUserData>()` (ya registrados en `injection.dart`).

## 4. Navegación post-agregado

- [x] 4.1 En `lib/features/sources/presentation/screens/add_source_screen.dart`, cambiar `Navigator.of(context).pop(true)` por `Navigator.of(context).pop(state.source)` en el listener de `AddSourceSuccess`.
- [x] 4.2 En `lib/features/sources/presentation/screens/sources_screen.dart`, cambiar el FAB para esperar `NewsSource?` en vez de `bool?` del `push('/sources/add')`; si vuelve una fuente no nula, recargar `SourcesCubit` (como hoy) y además navegar a `context.push('/sources/${source.id}?justAdded=true', extra: source)`.
- [x] 4.3 Actualizar `test/widget/features/sources/add_source_screen_test.dart` (el pop ahora lleva el `NewsSource`, no `true`) y `test/widget/features/sources/sources_screen_test.dart` (recarga + navegación al detalle tras agregar).

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` sin warnings nuevos.
- [x] 5.2 Correr `flutter test test/unit/features/sources/ test/widget/features/sources/` y confirmar que todo pasa.
- [x] 5.3 Probar manualmente en la app: agregar una fuente nueva y confirmar que aparece el spinner en el detalle y luego los artículos (si el feed tiene contenido reciente), y que la lista de fuentes al volver atrás ya muestra la fuente nueva.
