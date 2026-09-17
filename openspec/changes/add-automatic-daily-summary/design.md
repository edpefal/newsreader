## Context

Dos piezas de infraestructura existentes son relevantes acá:

- **`sync-feeds`** (`supabase/functions/sync-feeds/index.ts`) hoy solo se invoca on-demand con el JWT de un usuario, y procesa como máximo `MAX_SOURCES_PER_INVOCATION` (20) fuentes **de ese usuario**, ordenadas por `last_synced_at` ascendente. Ver `centralize-feed-fetching/design.md` y `fix-pull-to-refresh-partial-sync` para el historial de por qué existe ese tope (protección contra `WORKER_RESOURCE_LIMIT`, confirmado en producción).
- Un **cron para `sync-feeds`** ya existió una vez (`centralize-feed-fetching`, migraciones `20260727010000`/`20260727020000`/`20260727230000`) y se sacó — no porque no funcionara técnicamente (la versión final, con una invocación por usuario y `timeout_milliseconds: 60000` en `pg_net`, sí resolvía el resource limit), sino porque no había ningún feature que necesitara frescura sin que alguien abriera la app. Ese feature ahora existe (este change), así que se reintroduce cron, con un diseño distinto al que se sacó (ver Decisión 1).
- **`summarize-articles`** (`supabase/functions/summarize-articles/index.ts`) es un proxy a Gemini invocado por el cliente, con el prompt/voz editorial embebidos y el `language` recibido como parámetro del request. Genera un único `DailySummary` a partir de artículos que el cliente arma localmente desde su Hive box. No tiene noción de "usuario sin sesión en vivo".
- El resumen diario se persiste en Postgres (tabla `daily_summaries`) y ya se sincroniza al dispositivo vía el mecanismo existente de `SyncUserData` (pull genérico por `updated_at`), sin cambios necesarios ahí: si el cron escribe la fila en Postgres, el próximo sync del cliente la baja igual que hoy.
- `entitlements` (tabla, capability `subscription-entitlements`) ya es consultable directamente con `service_role`, sin necesitar una sesión de usuario en vivo — el mismo mecanismo que usa `summarize-articles` hoy vía `entitlement.ts`.

## Goals / Non-Goals

**Goals:**
- El contenido de los usuarios elegibles (suscriptos, o gratis los lunes) está fresco en el servidor antes de que el cron intente generar su resumen del día.
- El resumen diario de un usuario elegible aparece automáticamente, sin que abra la app, en un horario razonable de su día local.
- Una falla transitoria de un día puntual se recupera sola en la siguiente corrida del cron, sin intervención del usuario.
- Reintroducir cron sin repetir el error de diseño original (una invocación por usuario con todas sus fuentes) que causó el `WORKER_RESOURCE_LIMIT` la primera vez.

**Non-Goals:**
- No se implementa un selector de timezone explícito en la UI — el offset se infiere del dispositivo automáticamente.
- No se garantiza una hora exacta al minuto de generación — "razonablemente temprano en la mañana local" alcanza para el caso de uso (leer noticias del día).
- No se resuelve manejo de DST perfecto (ver Decisión 4 y Riesgos) — se acepta una imprecisión de hasta una hora en las semanas de cambio de horario.
- No se toca `article-summaries` (resumen por artículo individual), que sigue siendo manual.

## Decisions

### Decisión 1: Freshness en background — lote global, no por usuario (evita el error de diseño anterior)
Se agrega a `sync-feeds` un modo "background": cuando el caller es `service_role` (no un JWT de usuario) y el body incluye `{ "mode": "background" }`, la función ignora el filtro `user_id` y selecciona las `MAX_SOURCES_PER_INVOCATION` (20) fuentes **de toda la tabla `sources`** con `last_synced_at` más antiguo (o nulo), sin importar de qué usuario son. Un cron (`pg_cron` + `pg_net`, fire-and-forget) invoca este modo cada pocos minutos.

**Por qué esto no repite el error de `centralize-feed-fetching`**: la falla original fue agrupar todas las fuentes de todos los usuarios en una sola invocación (89 fuentes entre 2 cuentas). Acá el tamaño del lote sigue siendo el mismo 20 ya probado estable, sin importar cuántos usuarios o fuentes existan en total — el sistema converge a "todo fresco" en background con el tiempo, nunca arriesgando el resource limit de una invocación individual.

**Alternativa descartada**: repetir el diseño anterior (una invocación por usuario, cron con `cron.schedule` iterando `distinct user_id`). Se descarta porque escala mal: con más usuarios, más invocaciones por corrida de cron, cada una todavía acotada a 20 fuentes de ESE usuario — un usuario con muchas fuentes seguiría sin cubrirse en una sola invocación de todos modos (mismo problema que motivó `fix-pull-to-refresh-partial-sync`, ahora en el cron). El lote global evita esa complejidad extra.

### Decisión 2: Nueva capability `user-preferences` — tabla `user_preferences (user_id, locale, utc_offset_minutes, updated_at)`
Se persiste `locale` (string: `"es"`/`"en"`/`"fr"`) y `utc_offset_minutes` (entero, offset actual del dispositivo respecto a UTC) por usuario. El cliente actualiza esta fila en cada ciclo de `SyncUserData` (mismo patrón que `sources`/`articles`: upsert vía `_cloudSyncClient.upsert()`), leyendo el locale activo de `AppLocalizations`/`Localizations.localeOf(context)` equivalente y el offset de `DateTime.now().timeZoneOffset`.

**Por qué offset en minutos y no timezone IANA (ej. `America/Mexico_City`)**: evita agregar una dependencia nueva (`flutter_timezone` o similar) solo para este feature. El trade-off es que el offset no captura cambios de horario de verano automáticamente entre sincronizaciones — se acepta como imprecisión menor (ver Riesgos), consistente con Non-Goals.

**Alternativa descartada**: pedirle el timezone al usuario explícitamente en Settings. Se descarta por agregar fricción de onboarding a un dato que el dispositivo ya conoce.

### Decisión 3: Nueva Edge Function `generate-daily-summaries`, invocada por cron cada hora
Un cron (`pg_cron` + `pg_net`, igual mecanismo que Decisión 1) invoca `generate-daily-summaries` cada hora. Esa función, con `service_role`:

1. Calcula, para cada usuario con al menos una fuente, su "hora local actual" (`now() + utc_offset_minutes` de `user_preferences`, default UTC+0 si no hay preferencia registrada todavía).
2. Filtra a los usuarios cuya hora local actual ya pasó un umbral fijo (`06:00` local) Y que no tengan ya un `DailySummary` para su fecha local de hoy.
3. De esos, filtra por elegibilidad: `entitlements.is_active = true` (cualquier día), o sin suscripción activa y la fecha local de hoy de ese usuario cae en lunes.
4. Para cada usuario que pasa ambos filtros, arma el resumen igual que hace hoy `summarize-articles` (reutilizando el prompt/voz editorial y la lógica de agrupación por fuente) pero leyendo los artículos directamente de Postgres (`articles` donde `user_id` y `published_at` caen en la fecha local de ese usuario), en el `locale` de `user_preferences`, y persiste el `DailySummary` resultante.

**Reintento**: si la generación de un usuario falla (error de Gemini, timeout), no se persiste nada — la siguiente corrida horaria vuelve a intentarlo (sigue cumpliendo "no tiene `DailySummary` de hoy"), hasta que su fecha local cambie (ahí ese día se pierde, sin reintento retroactivo — ver Riesgos) o hasta que se genere exitosamente.

**Por qué cada hora y no más seguido**: alcanza para "razonablemente temprano en la mañana" sin multiplicar invocaciones innecesarias contra Gemini/Postgres para usuarios que ya tienen su resumen de hoy (el filtro del paso 2 los descarta rápido, pero igual son N filas evaluadas por corrida).

### Decisión 4: Elegibilidad gratis por día de la semana, sin contador persistido
Se elimina la tabla/contador `daily_summary_free_usage` (y los requirements asociados en `ai-usage-budget`). La elegibilidad gratis pasa a ser puramente derivada: `dayOfWeek(fecha local del usuario) == lunes`. No hace falta un contador ni su reset semanal — el propio calendario ya resetea la elegibilidad cada semana, y el chequeo de "ya existe `DailySummary` de hoy" (que de todos modos hace falta para idempotencia del cron) ya evita una segunda generación el mismo lunes.

**Alternativa descartada**: mantener el contador pero hacerlo incrementar automáticamente. Se descarta por agregar estado redundante — el día de la semana ya es la única señal que determina elegibilidad, no hace falta persistir nada más.

### Decisión 5: El cliente pierde toda la superficie de generación manual
`GenerateDailySummary` (use case), el botón "Crear resumen", el indicador de cupo gratis, y el disparo de paywall desde la pantalla de Resúmenes se eliminan del cliente — no se dejan como fallback ni se ocultan detrás de una flag. La pantalla de Resúmenes pasa a ser lista + detalle únicamente, alimentada por el mismo mecanismo de sync ya existente. `summarize-articles` (el endpoint HTTP) deja de tener caller desde la app; su lógica de prompt se traslada/reutiliza en `generate-daily-summaries`, no se mantienen dos copias del mismo prompt.

**Por qué eliminar en vez de dejar como fallback**: mantener ambos caminos (manual + automático) duplicaría la lógica de generación (dos lugares con el mismo prompt y las mismas reglas de agrupación por fuente) y reintroduciría exactamente la ambigüedad de "quién generó esto" que se buscó evitar. El usuario confirmó explícitamente este alcance (ver exploración previa a esta propuesta).

## Risks / Trade-offs

- **[Riesgo] Imprecisión de hasta ~1 hora en semanas de cambio de horario (DST)** (ver Decisión 2) → Aceptado: el offset se actualiza en la siguiente sincronización del usuario después del cambio; el peor caso es un resumen generado una hora antes/después de las 6am locales esperadas, una sola vez al año por usuario.
- **[Riesgo] Un usuario cuyo dispositivo nunca sincronizó `user_preferences`** (cuenta muy vieja, o justo después de este deploy) → Mitigación: default `utc_offset_minutes = 0` (UTC) y `locale = "en"` hasta la primera sincronización post-deploy; se corrige solo apenas el usuario abre la app una vez.
- **[Riesgo] Reintroducir `pg_cron`/`pg_net`/Vault reintroduce la complejidad de mantenimiento que se sacó en `centralize-feed-fetching`** → Aceptado explícitamente: a diferencia de esa vez, ahora hay un feature real (resumen automático) que lo justifica, y el diseño del lote (Decisión 1) evita repetir la falla operativa original.
- **[Riesgo] Costo de Gemini para usuarios suscriptos que nunca abren la app** → Aceptado: ver `proposal.md` — es el costo esperado del feature tal como se pidió (automático para suscriptores, sin importar si abren la app).
- **[Trade-off] Se pierde la capacidad de reintentar manualmente un resumen fallido** (antes existía un botón de reintento en el estado de error) → Aceptado como parte de la Decisión 5; el reintento pasa a ser exclusivamente el del cron (Decisión 3), acotado al mismo día local.
- **[Riesgo] Falla de generación cerca del cambio de día local del usuario** → Si la última corrida horaria antes del cambio de fecha local falla, ese día se pierde sin reintento retroactivo (el reintento de la Decisión 3 solo aplica "mientras siga siendo el mismo día local"). Aceptado como límite natural del mecanismo, consistente con la respuesta del usuario en la exploración previa.
