## Why

Al volver del background, la app sincroniza (`SyncUserData` + fetch de feeds) sin ningún indicador visual. A diferencia del login — que ya muestra un estado de carga con mensaje mientras sincroniza (ver capability `cloud-sync`) — el caso de resume deja al usuario sin ninguna señal de que algo está pasando, incluso cuando ya hay artículos cargados en pantalla (por lo que el estado de carga a pantalla completa que usa el login no aplica acá).

## What Changes

- Se agrega un indicador de carga visible en el Inbox mientras la app sincroniza tras volver del background: un `LinearProgressIndicator` en la parte superior de la pantalla, debajo del título/AppBar.
- El indicador se muestra sin ocultar el contenido ya cargado del Inbox (a diferencia del estado de carga a pantalla completa usado en el login, donde no hay contenido previo que preservar).
- Se oculta automáticamente al terminar la sincronización (éxito o error).

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `cloud-sync`: se agrega el requirement de que la sincronización disparada al volver del background sea visible para el usuario mediante un indicador de progreso no bloqueante, en vez de no dar ninguna señal.

## Impact

- `lib/features/inbox/presentation/cubit/inbox_cubit.dart`: nuevo estado o campo para señalar "sincronizando en segundo plano" sin descartar los artículos ya cargados (a diferencia de `InboxLoading`, que reemplaza el contenido).
- `lib/features/inbox/presentation/screens/inbox_screen.dart`: renderizar el `LinearProgressIndicator` debajo del `AppBar` cuando ese estado esté activo.
- `lib/presentation/app/app.dart`: el handler de `didChangeAppLifecycleState` (resume) pasa a usar el nuevo mecanismo en vez de solo llamar a `SyncUserData.execute()` + `loadArticles()` sin feedback visual.
