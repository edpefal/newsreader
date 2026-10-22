## Why

El 2 de octubre una migración eliminó la tabla `daily_summary_free_usage` (y sus dos funciones) porque el resumen diario automático (#50) quitó el flujo manual que la usaba. Se aplicó tras verificar la adopción con builds de TestFlight, pero **antes** de que la `1.9.0`, que ya no la consulta, estuviera pública: la 1.9.0 pasó a `READY_FOR_DISTRIBUTION` en la App Store el 6 de octubre. Entre tanto la App Store servía la `1.8.0` build 18, que consulta esa tabla como último paso de **cada** sincronización. Sin la tabla, Postgrest responde `PGRST205` y la sincronización falla en cada ciclo.

El efecto es peor de lo que sugiere un error de sincronización: en ese build, `syncAfterSignIn()` espera la sincronización **sin manejar errores** (el arreglo de resiliencia #45 es posterior), así que tras iniciar sesión el Inbox se queda en el estado de carga indefinidamente. Un usuario nuevo se dio de alta hoy y reintentó durante horas; Sentry registra el mismo error para 3 usuarios (`REEVO-PROD-A`, `-B` y `-G`, todos del release `1.8.0+18`; A y B estaban resueltos y se reabrieron).

## What Changes

- **Servidor (migración, solo prod):** recrear `daily_summary_free_usage` **vacía**, con el esquema original, RLS activo y la política de lectura del propio usuario, como compatibilidad temporal para los clientes `1.8.x`. No se recrean las funciones `security definer` ni se escribe ninguna fila.
- **Criterio de retiro documentado y accionable:** la tabla se elimina cuando ya no haya usuarios activos en `1.8.x` (PostHog) ni eventos `PGRST205` nuevos (Sentry).
- **Se acepta, y queda dicho explícitamente,** que la generación manual de resumen diario en la 1.8.x sigue sin funcionar: ya no existe en el servidor. Lo que se arregla es iniciar sesión y sincronizar.
- Sin cambios de cliente, de pantallas ni de textos: no hay claves de i18n y el layout de iPad no se ve afectado.

## Capabilities

### New Capabilities
- `legacy-client-compatibility`: obligaciones temporales del servidor hacia clientes ya publicados que dependen de recursos que el cliente actual no usa, empezando por la tabla de cupo gratis semanal para la `1.8.x`, con su condición de retiro.

### Modified Capabilities
<!-- Ninguna -->

## Impact

- Nueva migración en `supabase/migrations/` (`daily_summary_free_usage` vacía con RLS y política de lectura).
- Se aplica **solo en `reevo` (prod)**: dev no tiene instalaciones de la 1.8.x. Debe confirmarse el proyecto con el usuario antes de aplicar.
- Se aplica con la herramienta de migraciones de Supabase, **no** con `supabase db push`: las migraciones del 16 de septiembre figuran en Supabase con otro número de versión que en el repo (desajuste preexistente) y `db push` intentaría reaplicarlas.
- Un test del cliente actual verifica que `SyncUserData` no consulta esta tabla.
- Monitoreo: `REEVO-PROD-A/B/G` se marcan como resueltos solo cuando dejen de llegar eventos.
- Lección de proceso, para una tarea aparte: retirar un recurso del servidor solo después de que la versión sin esa dependencia esté pública y adoptada.
