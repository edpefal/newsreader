## Why

Hoy el resumen diario (`daily-summaries`) es 100% manual: el usuario tiene que abrir la app y tocar "Crear resumen" para generarlo, y solo existe si ese gesto ocurrió ese día. Se decidió (ver exploración previa a esta propuesta) que el resumen diario pase a generarse automáticamente en el servidor, sin que el usuario tenga que hacer nada, para que esté listo cuando abra la app. Esto requiere, como prerrequisito, que los artículos del día ya estén frescos en el servidor sin depender de que alguien haga pull-to-refresh — hoy el fetch de feeds (`feed-polling`) es puramente on-demand (ver `centralize-feed-fetching`, Decisión 1: se descartó explícitamente un cron baseline en ese momento, por no haber un caso de uso real que lo justificara. Este change es ese caso de uso).

## What Changes

- **Freshness de feeds en background**: `sync-feeds` gana un modo adicional, invocado por un cron del lado del servidor (no por un usuario), que procesa un lote acotado de las fuentes menos recientemente sincronizadas **de toda la base** (no por usuario), con la misma protección de tamaño de lote que ya existe hoy contra `WORKER_RESOURCE_LIMIT`. El modo on-demand existente (pull-to-refresh, login, agregar fuente) no cambia.
- **Resumen diario 100% automático, sin generación manual**: se elimina por completo el botón "Crear resumen", el paywall disparado desde ese botón, y el indicador de cupo gratis semanal. Un cron del lado del servidor genera el resumen diario de cada usuario automáticamente, a una hora local razonable de su día, sin acción del usuario.
- **Elegibilidad**: usuarios con suscripción activa reciben el resumen automático todos los días; usuarios sin suscripción lo reciben automáticamente solo los lunes (mismo cupo "1 por semana" que existe hoy, ahora fijo a ese día en vez de disponible cualquier día de la semana a demanda).
- **Reintento**: si la generación automática de un usuario falla un día dado (error de la API de IA, timeout), el cron vuelve a intentarlo en su siguiente corrida, mientras siga siendo el mismo día local de ese usuario y todavía no exista su `DailySummary` de hoy.
- **Idioma del resumen sin dispositivo en vivo**: se persiste el locale y el offset horario (UTC) del dispositivo del usuario en la nube (nueva capability `user-preferences`), actualizado en cada sincronización, para que el cron sepa en qué idioma generar el texto y qué hora local le corresponde a cada usuario sin depender de una sesión activa.
- **BREAKING**: se elimina la generación manual de resumen diario y el cupo gratis semanal como cupo "a demanda" — un usuario sin suscripción ya no puede elegir cuándo generar su resumen gratis de la semana; lo recibe automáticamente el lunes.
- La pantalla de Resúmenes pasa a ser de solo lectura (lista + detalle); sigue mostrando los resúmenes que van llegando vía la sincronización con la nube ya existente, sin ningún cambio en cómo se listan o se ven en detalle.

## Capabilities

### New Capabilities
- `user-preferences`: persiste, por usuario, el locale activo y el offset horario UTC del dispositivo, sincronizado en cada ciclo de `SyncUserData`, para que procesos del lado del servidor sin sesión de usuario en vivo (como el cron de resumen diario) sepan en qué idioma y a qué hora local generar contenido para ese usuario.

### Modified Capabilities
- `feed-polling`: agrega un modo de fetch en background disparado por un cron del servidor (no por un cliente), acotado a un lote fijo de fuentes globalmente menos recientemente sincronizadas, independiente de cualquier usuario en particular.
- `daily-summaries`: reemplaza la generación manual (botón, paywall al tocar, indicador de cupo gratis, rechazo por falta de suscripción/cupo en el momento del toque) por generación automática server-side, con elegibilidad basada en suscripción activa (diario) o día de la semana (lunes, sin suscripción), reintento entre corridas del cron dentro del mismo día local del usuario, e idioma/hora local derivados de `user-preferences` en vez de un request en vivo. Las capabilities de listado, detalle, persistencia de `sourceBlocks`, y protección contra inyección de instrucciones vía el contenido de los artículos no cambian.
- `ai-usage-budget`: se elimina el contador semanal gratis de resumen diario (`Límite semanal gratis de resumen diario por usuario` y sus requirements asociados de reset/atomicidad/consulta) — la elegibilidad gratis pasa a derivarse directamente del día de la semana (lunes) en `daily-summaries`, sin necesitar un contador persistido aparte.

## Impact

- **Nueva Edge Function** (o modo nuevo dentro de una existente) para la generación automática del resumen diario, invocada por `pg_cron`/`pg_net` — reintroduce esa infraestructura (removida en `centralize-feed-fetching` por no tener, en ese momento, un caso de uso que la justificara).
- `supabase/functions/sync-feeds/index.ts`: nuevo modo de invocación "background" (batch global, sin JWT de usuario).
- `supabase/functions/summarize-articles/`: su lógica de prompt/voz editorial se reutiliza desde el nuevo proceso automático; el endpoint HTTP invocable por el cliente deja de tener caller (nadie lo invoca más desde la app).
- Nueva tabla `user_preferences` (locale, offset UTC) + su sincronización en `SyncUserData`.
- Se elimina el contador `daily_summary_free_usage` (tabla, modelo, datasource, repositorio) y el flujo cliente de generación manual: `GenerateDailySummary` (use case), el botón y su Cubit/estado asociado en `features/summaries/presentation/`, el paywall disparado desde esa pantalla.
- Nuevas migraciones SQL: tabla `user_preferences`, cron jobs (feed freshness + resumen diario), secretos de Vault para las nuevas invocaciones server-to-server.
- **Fuera de alcance de este change**: no se modifica el resumen por artículo individual (`article-summaries`), que sigue siendo manual y sin cambios.
