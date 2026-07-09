## Why

Al completar una importación OPML, el inbox no se actualiza automáticamente — el usuario tiene que hacer pull-to-refresh manualmente para ver los artículos de las fuentes recién importadas. Esto se debe a que `ImportOpmlScreen` no dispara `syncAndReload()` en `InboxCubit` al terminar.

## What Changes

- Al completar una importación OPML exitosa, disparar `InboxCubit.syncAndReload()` antes de cerrar `ImportOpmlScreen`
- Esto garantiza que las fuentes recién importadas se sincronicen y sus artículos aparezcan en el inbox al regresar al home

## Capabilities

### New Capabilities

_(ninguna)_

### Modified Capabilities

- `opml-import`: El flujo de importación ahora dispara una sincronización del inbox al completarse exitosamente.

## Impact

- `lib/features/sources/presentation/screens/import_opml_screen.dart` — agregar llamada a `InboxCubit.syncAndReload()` en el handler de `ImportOpmlDone`
- `InboxCubit` ya está provisto en el root del árbol de widgets, accesible vía `context.read<InboxCubit>()`
