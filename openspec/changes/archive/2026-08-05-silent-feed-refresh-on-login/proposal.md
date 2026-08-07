## Why

Al iniciar sesión, el Inbox se puebla únicamente con lo que ya estaba en Postgres (`SyncUserData`), que solo se actualiza cuando algún dispositivo de la cuenta hace pull-to-refresh. Si nadie refrescó en varios días, el usuario ve artículos viejos justo al momento de abrir la app — la primera impresión es de una app desactualizada, aunque las fuentes sigan activas.

## What Changes

- `InboxCubit.syncAfterSignIn()` dispara, después de mostrar el Inbox con los datos ya sincronizados, un fetch de feeds en segundo plano (`FeedSyncTrigger`) equivalente al que ya hace el pull-to-refresh manual — sin bloquear la UI con un spinner de pantalla completa.
- Mientras ese fetch en segundo plano está en curso, se reutiliza el indicador no invasivo ya existente (`isSyncingInBackground` / `_BackgroundSyncIndicator`). Al terminar, se vuelve a sincronizar y recargar el Inbox con los artículos nuevos.
- El fetch en segundo plano tras login es completamente silencioso: a diferencia del pull-to-refresh manual, no muestra snackbars de error de red ni de fuentes fallidas — es una mejora automática, no una acción pedida explícitamente por el usuario.
- Se agrega un guard de deduplicación en `InboxCubit` para que el fetch silencioso de login y un pull-to-refresh manual nunca disparen dos invocaciones simultáneas de `sync-feeds` para el mismo usuario; si se solapan, ambos esperan la misma llamada en curso.
- Fuera de alcance explícito: `syncInBackground()` (resume desde background) no cambia en este change — sigue sin disparar fetch de feeds.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `cloud-sync`: el requirement "Sincronización automática al iniciar sesión" se amplía para incluir una fase de fetch de feeds en segundo plano tras la sincronización inicial, con su propio indicador de progreso no invasivo y sin feedback de error visible.
- `feed-polling`: el requirement "Fetch on-demand disparado por pull-to-refresh" se amplía — el fetch server-side ya no se dispara solo por pull-to-refresh manual, sino también automáticamente tras un login exitoso, reusando la misma invocación y el mismo tope de fuentes.

## Impact

- `lib/features/inbox/presentation/cubit/inbox_cubit.dart`: `syncAfterSignIn()` pasa a disparar el fetch en segundo plano tras el reload inicial; `syncAndReload()` se ajusta para compartir el guard de deduplicación con `syncAfterSignIn()`.
- `lib/features/inbox/presentation/screens/inbox_screen.dart`: sin cambios funcionales — `_BackgroundSyncIndicator` ya cubre el nuevo caso de uso tal cual está.
- No hay cambios de servidor: se reusa `FeedSyncTrigger`/`sync-feeds` (Edge Function) sin modificaciones, mismo tope de 20 fuentes por invocación y mismo timeout de 90s en el cliente.
