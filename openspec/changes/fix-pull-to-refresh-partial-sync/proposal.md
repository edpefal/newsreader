## Why

El pull-to-refresh del Inbox a veces solo trae una parte de los artículos nuevos: la Edge Function `sync-feeds` procesa como máximo `MAX_SOURCES_PER_INVOCATION` (20) fuentes por invocación —una protección deliberada contra el `WORKER_RESOURCE_LIMIT` de Supabase Edge Functions, confirmada en producción con ~45 fuentes de una sola cuenta (ver `openspec/changes/archive/2026-07-29-centralize-feed-fetching/design.md`, Decisión 1—. Un usuario con más fuentes que ese tope solo consigue que se sincronicen las menos recientemente sincronizadas en cada invocación; el resto queda para el próximo pull-to-refresh. Desde la experiencia del usuario esto se siente como que el primer intento "falló" o "se quedó a medias", aunque el servidor respondió correctamente dentro de su límite.

## What Changes

- El pull-to-refresh del Inbox reintenta el fetch de feeds dentro del **mismo gesto**, en loop, hasta cubrir todas las fuentes del usuario o alcanzar un tope de vueltas — sin que el usuario tenga que repetir el swipe manualmente para ponerse al día.
- El indicador de carga (`RefreshIndicator`) sigue girando mientras el loop continúa; el feedback de errores (snackbar de "fuentes fallidas" u "offline") se sigue mostrando una sola vez al final, agregando los resultados de todas las vueltas, no por cada invocación individual.
- No se modifica la Edge Function `sync-feeds` ni su tope de fuentes por invocación: la protección contra `WORKER_RESOURCE_LIMIT` se mantiene intacta. El cambio es puramente client-side, en cómo se orquestan las llamadas repetidas.
- Explícitamente fuera de alcance (evaluado y descartado en la exploración previa a esta propuesta): subir `MAX_SOURCES_PER_INVOCATION` (no resuelve el caso general y arriesga el resource limit) y reintroducir un cron en background (feature aparte, con sus propias preguntas de timezone/costo/cuota que se resuelve en un change separado).

## Capabilities

### Modified Capabilities
- `feed-polling`: el requirement "Fetch on-demand disparado por pull-to-refresh, por login, o al agregar una fuente" pasa a exigir que el pull-to-refresh reintente automáticamente hasta cubrir todas las fuentes del usuario (o un tope explícito de vueltas), en vez de conformarse con una sola invocación del fetch de feeds.

## Impact

- `lib/features/inbox/presentation/cubit/inbox_cubit.dart` (`syncAndReload()`): pasa a loopear la invocación de `FeedSyncTrigger.execute()` en vez de llamarla una sola vez.
- `lib/core/feed/feed_sync_trigger.dart` (`FeedSyncResult`): puede necesitar exponer información adicional (ej. total de fuentes del usuario, o si sync-feeds priorizó pero no alcanzó a cubrir todo) para que el cliente sepa cuándo detener el loop — se define el mecanismo exacto en `design.md`.
- Sin cambios en la Edge Function `sync-feeds` (`supabase/functions/sync-feeds/index.ts`) ni en su límite de fuentes por invocación.
- Sin cambios de UI visibles más allá de que el `RefreshIndicator` puede girar más tiempo cuando el usuario tiene muchas fuentes con contenido nuevo.
