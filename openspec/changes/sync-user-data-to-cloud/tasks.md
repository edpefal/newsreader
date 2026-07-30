## 1. Esquema de base de datos (Supabase Postgres)

- [x] 1.1 Crear migración SQL con las tablas `sources`, `articles`, `daily_summaries`, cada una con `user_id uuid references auth.users(id)`, campos espejo de sus respectivos modelos Hive (incluyendo `updated_at` y `deleted_at` donde aplica), e índice por `(user_id, updated_at)`.
- [x] 1.2 Habilitar RLS en las 3 tablas y agregar policies `select`/`insert`/`update` restringidas a `user_id = auth.uid()` (sin policy de `delete` física — el borrado es lógico vía `deleted_at`).
- [x] 1.3 Aplicar la migración (`supabase db push`) y verificar que las tablas y policies existen en el proyecto.

## 2. Modelos Hive y entidades

- [x] 2.1 Agregar `updatedAt` (`DateTime`) y `deletedAt` (`DateTime?`) a `NewsSourceModel` (HiveField 8 y 9) y a la entidad `NewsSource`.
- [x] 2.2 Agregar `updatedAt` (`DateTime`) y `deletedAt` (`DateTime?`) a `ArticleModel` (HiveField 15 y 16) y a la entidad `Article`.
- [x] 2.3 Agregar `updatedAt` (`DateTime`) a `DailySummaryModel` (HiveField 5) y a la entidad `DailySummary` (sin `deletedAt`).
- [x] 2.4 Correr `dart run build_runner build --delete-conflicting-outputs` para regenerar los TypeAdapters.
- [x] 2.5 Actualizar `HiveArticleDatasource`, `HiveSourceDatasource`, `HiveSummaryDatasource` para estampar `updatedAt = DateTime.now()` en cada escritura (save/update), y soportar borrado lógico (`deletedAt`) en vez de borrado físico inmediato donde corresponda.
- [x] 2.6 Actualizar tests existentes de estos datasources/modelos para reflejar los campos nuevos, sin romper ningún test de use cases (que no deberían necesitar cambios). Confirmado: 0 tests de use cases necesitaron cambios. Se agregó cobertura nueva de soft-delete en `hive_article_datasource_test.dart`.

## 3. Cliente de sincronización

- [x] 3.1 Crear `lib/core/sync/cloud_sync_client.dart`: interfaz `CloudSyncClient` con métodos para upsert y query-by-updated-at-since sobre cada tabla (`sources`, `articles`, `daily_summaries`).
- [x] 3.2 Crear `lib/core/sync/supabase_cloud_sync_client.dart`: implementación concreta sobre `supabase_flutter`, sin exponer el SDK fuera de esta capa.
- [x] 3.3 Registrar `CloudSyncClient` en `lib/core/di/injection.dart`.

## 4. Use case SyncUserData

- [x] 4.1 Crear `lib/features/sync/domain/usecases/sync_user_data.dart`. Depende directamente de los datasources locales (no de los repositorios de dominio) porque necesita ver también los registros soft-deleted; se extendieron `ArticleLocalDataSource`/`SourceLocalDataSource`/`SummaryLocalDataSource` con `getChangedSince`/`applyRemote`/`purge`, y `AuthClient` con `currentUserId`.: lee el cursor `lastSyncedAt` (nuevo key en el Hive box de settings), ejecuta push (subir local con `updatedAt > cursor`, o todo si el cursor es `null`) y pull (bajar remoto con `updated_at > cursor`, aplicando soft-delete/borrado físico local cuando corresponda) para las 3 tablas, y actualiza el cursor al finalizar.
- [x] 4.2 Escribir tests unitarios para `SyncUserData` cubriendo: primera sincronización (cursor `null`, sube todo lo local), sincronización incremental (solo sube/baja lo cambiado), aplicación de soft-delete remoto como borrado físico local, y last-write-wins en conflictos simulados.
- [x] 4.3 Registrar `SyncUserData` en `lib/core/di/injection.dart`.
- [x] 4.4 Disparar `SyncUserData` en `main.dart` al arrancar la app. Ajuste respecto al plan original: `SyncSources` en realidad no corre en `main.dart` hoy (solo vía pull-to-refresh desde `InboxCubit.syncAndReload()`), así que no hay un llamado paralelo existente que replicar — `SyncUserData` se agrega solo, y ya maneja internamente el caso sin sesión activa como no-op (no hace falta chequear sesión antes de llamarlo).

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` y resolver cualquier warning.
- [x] 5.2 Correr `flutter test` y confirmar que todo pasa, incluyendo los tests existentes de use cases (no deberían requerir cambios). 211/211 pasan, sin cambios en ningún test de use case existente.
- [x] 5.3 Probar manualmente con dos dispositivos (o un dispositivo + el emulador) logueados con la misma cuenta: marcar un artículo como leído en uno, sincronizar en el otro, confirmar que se refleja. Confirmado con emulador Android + simulador iOS.
- [x] 5.4 Probar manualmente: agregar una fuente en un dispositivo, confirmar que aparece en el otro tras sincronizar. Confirmado.
- [x] 5.5 Probar manualmente: eliminar una fuente en un dispositivo, confirmar que desaparece (junto con sus artículos) en el otro tras sincronizar. Hallazgo: el borrado se "resucitaba" con artículos nuevos en el siguiente pull-to-refresh porque `syncAndReload()` disparaba `sync-feeds` (fetch RSS del servidor) *antes* de subir el borrado local, así que el servidor todavía veía la fuente como activa y le creaba artículos nuevos, que el pull de después bajaba al Inbox. Corregido: `InboxCubit.syncAndReload()` ahora sube el estado local (`SyncUserData`) antes de disparar `sync-feeds`, y vuelve a sincronizar después para bajar lo nuevo. Se agregó además `.is("deleted_at", null)` a la query de `sync-feeds/index.ts` como defensa adicional, y se desplegó a Supabase. Confirmado el fix con una fuente de prueba (agregar → eliminar → refresh repetido, sin resurrección).
- [ ] 5.6 Probar manualmente el caso de primer login con datos locales preexistentes: confirmar que esos datos aparecen en Postgres después del primer sync, y que un segundo dispositivo logueado con la misma cuenta los recibe. No reproducible con la app actual: el login es obligatorio desde el arranque (`router.dart` redirige a `/login` si no hay sesión), así que no existe ningún estado real de "datos locales sin cuenta" para probar. Queda cubierta indirectamente por el mismo camino de `SyncUserData` (cursor `null` → sube todo lo local) ya validado en 5.3-5.5 y en la verificación de 7.7.

## 6. Mejorar la frecuencia de sincronización

Hallazgo de la verificación manual: al sincronizar solo en el arranque en frío de la app (`main()`), un cambio hecho en otro dispositivo no se refleja hasta forzar el cierre completo de la app — mucha fricción para un caso de uso común (cambiar de app y volver). Se agregan dos disparadores más, sin llegar a tiempo real:

- [x] 6.1 Enganchar `SyncUserData` al pull-to-refresh existente del Inbox: `InboxCubit.syncAndReload()` pasa a llamar también a `SyncUserData.execute()` (además de `SyncSources.execute()`), reutilizando un gesto que el usuario ya conoce.
- [x] 6.2 Sincronizar también al volver del background (`AppLifecycleState.resumed`), no solo al abrir la app desde cero: agregar un `WidgetsBindingObserver` en `lib/presentation/app/app.dart` que dispare `SyncUserData.execute()` seguido de `InboxCubit.loadArticles()` al resumir.
- [x] 6.3 Actualizar `test/unit/features/inbox/presentation/cubit/inbox_cubit_test.dart` con el mock de `SyncUserData` y verificar que `syncAndReload()` lo invoca.
- [x] 6.4 Correr `flutter analyze` y `flutter test` de nuevo para confirmar que no se rompió nada. Sin issues, 211/211 pasan.
- [x] 6.5 Probar manualmente: leer un artículo en un dispositivo, cambiar a otra app y volver en el segundo dispositivo (sin cerrarla del todo) — confirmar que se refleja sin necesidad de forzar el cierre completo. Confirmado (con background/resume también del lado que originó el cambio, para que el push corra antes del pull).

## 7. Limpiar datos locales al cerrar sesión

Hallazgo de la verificación manual: al probar con dos dispositivos se pudo haber quedado logueada una cuenta distinta en alguno de los dos (por las pruebas de Google/Apple), y como los datos locales de Hive no se limpiaban al cerrar sesión, sincronizar con una cuenta distinta sobre los mismos `id` locales generó un error real de RLS (`new row violates row-level security policy`, código 42501) — la política bloqueó correctamente el intento de pisar filas de otro usuario, pero expuso que cambiar de cuenta en el mismo dispositivo dejaba datos huérfanos de la cuenta anterior.

- [x] 7.1 Agregar `clearAll()` a `ArticleLocalDataSource`/`SourceLocalDataSource`/`SummaryLocalDataSource` (interfaces + implementaciones Hive).
- [x] 7.2 Crear `lib/features/sync/domain/usecases/clear_local_user_data.dart`: borra las 3 boxes locales y el cursor `lastSyncedAt`.
- [x] 7.3 Registrar `ClearLocalUserData` en `lib/core/di/injection.dart`.
- [x] 7.4 Enganchar `ClearLocalUserData.execute()` antes de `AuthClient.signOut()` en el `onTap` de "Cerrar sesión" del `NavigationDrawer`.
- [x] 7.5 Escribir test unitario para `ClearLocalUserData`.
- [x] 7.6 Correr `flutter analyze` y `flutter test` de nuevo. Sin issues, 212/212 pasan.
- [x] 7.7 Probar manualmente: cerrar sesión en un dispositivo, confirmar que el Inbox/Fuentes quedan vacíos, loguearse con una cuenta distinta, y confirmar que no aparece ningún dato de la cuenta anterior. Confirmado que los datos se limpian al cerrar sesión. Hallazgo: al loguearse de nuevo (primera vez o tras cerrar sesión) nada disparaba un sync — `InboxCubit` es un singleton que no se reconstruye al navegar de `/login` a `/` (el router solo redirige), así que el Inbox quedaba con el estado vacío previo al login hasta el próximo pull-to-refresh manual, aunque los datos ya estuvieran en la nube. Corregido: `_AppState` (`app.dart`) escucha `AuthClient.authStateChanges` y dispara `InboxCubit.syncAfterSignIn()` (nuevo método) en la transición sin-sesión → con-sesión. Se agregó además un estado de carga con mensaje ("Sincronizando fuentes...") para que el usuario vea que está pasando algo mientras sincroniza. Confirmado con la cuenta original (no se probó con una segunda cuenta distinta).

## 8. Ids determinísticos para artículos (evitar duplicados entre dispositivos)

Hallazgo de la verificación manual: `SyncSources` corre de forma independiente en cada dispositivo (cada uno hace su propio fetch RSS) y generaba un `id` aleatorio por artículo. Cuando dos dispositivos descubrían el mismo artículo (misma `articleUrl`) antes de sincronizar entre sí, cada uno le asignaba un `id` distinto — al sincronizar, Postgres terminaba con dos filas para el mismo artículo real, visible como un duplicado en el Inbox, y además marcar como leído en un dispositivo no afectaba a la copia del otro (ids distintos, sin relación).

- [x] 8.1 Agregar `generateFromSeed(String seed)` a `IdGenerator`, e implementarlo en `UuidIdGenerator` con UUID v5 (determinístico: mismo seed → mismo id siempre, en cualquier dispositivo).
- [x] 8.2 Cambiar `SyncSources` para generar el `id` del artículo con `generateFromSeed(articleUrl)` en vez de `generate()` (aleatorio).
- [x] 8.3 Correr `flutter analyze` y `flutter test`. Sin issues, 212/212 pasan (no hace falta actualizar mocks: `MockIdGenerator`/`FakeIdGenerator` extienden `Mock`, que soporta métodos nuevos de la interfaz automáticamente).
- [ ] 8.4 Nota para la verificación manual: los artículos ya sincronizados antes de este fix pueden seguir duplicados (tienen ids viejos distintos ya persistidos). Si aparecen duplicados remanentes en Postgres al retomar las pruebas, limpiarlos a mano (borrar filas duplicadas en la tabla `articles`) antes de continuar con 5.3.
