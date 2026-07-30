## Context

Hoy cada dispositivo hace fetch de RSS de forma independiente (`SyncSources`, corre client-side vía `HttpClient`/`FeedParser`), y `SyncUserData` sincroniza esos artículos entre dispositivos por push/pull comparando `updatedAt`. El problema de fondo: dos dispositivos que descubren el mismo artículo antes de sincronizar entre sí generan dos `id`s distintos para el mismo contenido real (identificado por `articleUrl`), y no hay forma de reconciliarlos después sin coordinación central. Un intento de mitigar esto con un `id` determinístico (hash de la URL) en el cliente no alcanza, porque solo aplica a artículos que el dispositivo todavía no tiene guardados — el historial ya creado con ids aleatorios queda huérfano para siempre.

Se decidió (ver exploración previa) adoptar el patrón estándar de lectores RSS multi-dispositivo: el servidor es el único que hace fetch de los feeds, y los clientes solo leen contenido + sincronizan estado de usuario.

Ya existe infraestructura relevante en el proyecto: `pg_cron` está habilitado (usado en `email-to-rss-generated-feeds` para un cleanup diario), y ya hay Edge Functions desplegadas (`create-feed`, `feed`, `inbound-email`, `summarize-articles`) siguiendo el mismo patrón de despliegue.

## Goals / Non-Goals

**Goals:**
- Eliminar la clase de bug "mismo artículo, ids distintos entre dispositivos" de raíz, con una garantía a nivel de base de datos (constraint único), no solo lógica de aplicación.
- Mantener la sensación de "refrescar ahora" del pull-to-refresh existente, sin que el cliente vuelva a parsear RSS.
- Mantener aislamiento de fallos por fuente (un feed roto no bloquea a los demás), igual que hoy.
- Reducir el payload de `SyncUserData`: el contenido de los artículos deja de subirse desde el cliente.

**Non-Goals:**
- Sincronización en tiempo real (push notifications de artículos nuevos) ni actualización en segundo plano sin interacción del usuario. Sigue siendo pull-based, exclusivamente vía pull-to-refresh (sin cron baseline — ver Decisión 1).
- Migrar/conservar el estado de lectura o favoritos del historial actual — se acordó borrón y cuenta nueva.
- Cambiar el mecanismo de `SyncUserData` para fuentes o resúmenes diarios — solo se acota el alcance para artículos.

## Decisions

### Decisión 1: Edge Function `sync-feeds`, solo invocable on-demand con el JWT del usuario (sin cron)
Una única Edge Function hace el fetch de feeds, autenticada con el JWT del usuario que llama (valida la sesión vía `auth.getUser`) y procesa solo sus propias fuentes. Corre internamente con `service_role` para escribir en `articles`/`sources` de ese usuario (RLS normalmente bloquearía escrituras cross-row si se usara el cliente autenticado directo), pero nunca acepta un `user_id` arbitrario como parámetro — el único usuario que puede sincronizar es el dueño del JWT.

**Se evaluó y se descartó un cron baseline** (`pg_cron` invocando la función periódicamente para todos los usuarios, sin depender de que alguien abra la app). Motivos:
- Agrega infraestructura y superficie de mantenimiento (`pg_cron`, `pg_net`, secretos en Vault) que no se justifica para una app de newsletters — no son feeds en vivo, la frescura en segundo plano no es un requisito real.
- **Confirmado en despliegue**: incluso acotado a una invocación por usuario con tope de fuentes por invocación, sostener el cron demandó varias vueltas de ajuste (timeout de `pg_net` insuficiente, límite de cómputo del Edge Function) — complejidad real pagada por un beneficio (frescura sin abrir la app) que el pull-to-refresh ya cubre en la práctica.
- El pull-to-refresh on-demand es el único disparador: mismo código, mismo tope de fuentes por invocación (ver más abajo), pero sin la complejidad de coordinar invocaciones periódicas.

Alternativas consideradas:
- Cron + on-demand en la misma función con modos duales: se implementó, se desplegó, y se terminó sacando (ver arriba) tras confirmar que el costo de mantenerlo no se justificaba.
- Que el on-demand dispare el fetch de TODOS los usuarios (no solo el que refresca): se descartó por costo/latencia innecesarios — el usuario que refresca solo necesita sus propias fuentes actualizadas ya.

**Tope de fuentes por invocación**: se agregó `MAX_SOURCES_PER_INVOCATION = 20` (las menos sincronizadas recientemente primero) y `CONCURRENCY = 1` tras confirmar en despliegue que procesar demasiadas fuentes en una sola invocación agota el presupuesto de cómputo del Edge Function (`WORKER_RESOURCE_LIMIT`, reproducido con ~45 fuentes de una sola cuenta). Una cuenta con más de 20 fuentes se termina de poner al día en pull-to-refresh sucesivos.

### Decisión 2: Dedupe por constraint único `(source_id, article_url)`, no por chequeo previo
En vez de un `SELECT` de existencia antes de cada `INSERT` (como hace hoy `articleExists` en el cliente), se agrega `unique(source_id, article_url)` en la tabla `articles` y se usa `INSERT ... ON CONFLICT DO NOTHING`. Esto garantiza dedupe incluso ante ejecuciones concurrentes (cron y on-demand solapados), algo que un chequeo `SELECT` previo no puede garantizar de forma segura ante condiciones de carrera.

### Decisión 3: El `id` de artículo pasa a ser generado por Postgres (`gen_random_uuid()`)
Se abandona la idea de un `id` determinístico calculado por el cliente (hash de URL) — ya no hace falta, porque solo el servidor crea artículos. Se usa el generador nativo de Postgres, consistente con `sources.id` y `daily_summaries.id`, que ya usan `gen_random_uuid()`.

### Decisión 4: `SyncUserData` dejar de subir contenido de artículos
Se modifica el use case existente (parte de `sync-user-data-to-cloud`, todavía no archivado) para que, en el caso de `articles`, el push solo incluya `id`, `is_read`, `is_favorite`, `deleted_at` y `updated_at` — nunca `title`/`content_html`/`excerpt`/etc. El pull sigue trayendo el registro completo (el cliente necesita el contenido para mostrarlo). Esto reduce la superficie de conflicto de last-write-wins: ya no puede haber una carrera entre "el servidor actualizó el contenido" y "el cliente subió una copia vieja del contenido".

Como esto toca directamente la delta spec `cloud-sync` que ya existe (sin archivar) dentro de `sync-user-data-to-cloud`, se edita esa delta spec in situ en vez de crear una segunda delta paralela para la misma capability — evita specs contradictorias sobre el mismo requirement.

### Decisión 5: Borrón y cuenta nueva para el historial de artículos
Se trunca `articles` en Postgres y se limpia la box local de artículos en cada dispositivo (mismo mecanismo que `ClearLocalUserData.clearAll()`, disparado manualmente una vez como parte de la migración, no como flujo de usuario). El primer fetch (cron o pull-to-refresh) repuebla todo con ids canónicos. Se pierde el estado de lectura/favoritos actual — decisión explícita del usuario para evitar la complejidad y riesgo de un script de reconciliación de duplicados.

### Decisión 6: `SyncSources` y su infraestructura de fetch client-side se eliminan, no se dejan como fallback
Se elimina el use case, su registro en DI, y las dependencias que solo él usaba del lado del dominio (`FeedParser`/`HttpClient` siguen existiendo como abstracciones porque las sigue usando `AddSource`/`FeedUrlResolver` para la detección de feed al agregar una fuente — eso no cambia). Se descartó mantenerlo como fallback de "fetch inmediato al agregar fuente" para no tener dos caminos de creación de artículos que haya que mantener consistentes con el dedupe del servidor.

## Risks / Trade-offs

- **[Riesgo] Sin cron, si nadie hace pull-to-refresh no aparece contenido nuevo** → Aceptado como trade-off explícito (ver Decisión 1): es el costo de evitar la complejidad de un cron baseline, razonable para una app de newsletters de uso personal.
- **[Riesgo] La Edge Function on-demand podría ser invocada en exceso (spam de pull-to-refresh) y golpear los feeds de origen innecesariamente** → Mitigación: no se implementa throttling en esta iteración (el gesto de pull-to-refresh ya es manual y poco frecuente en la práctica); queda como mejora futura si se observa abuso.
- **[Riesgo] Pérdida de datos al truncar `articles`** → Mitigación: es una decisión explícita y acordada; se ejecuta una sola vez, de forma controlada, como parte del despliegue de este change (no repetible ni accidental).
- **[Trade-off] La función de sync corre con `service_role` internamente, ampliando la superficie si tuviera un bug de autorización** → Mitigación: siempre valida el JWT del caller vía `auth.getUser` y solo opera sobre las fuentes de ese `user_id`; nunca acepta un `user_id` como parámetro del body.
- **[Riesgo, descubierto en despliegue] Fuentes individuales pueden colgarse indefinidamente (ej. algunos feeds de kill-the-newsletter.com no respondieron ni con timeout de curl plano)** → Mitigación: ya cubierto por el timeout de 10s por fuente (`AbortController`), que se confirmó funcionando correctamente en despliegue (esas fuentes aparecen en `failedSourceIds`, no cuelgan la invocación completa).

## Migration Plan

1. Desplegar la migración SQL: constraint único en `articles`, id generado por el servidor, truncar `articles`.
2. Desplegar la Edge Function `sync-feeds` (solo modo on-demand, JWT de usuario).
3. Actualizar el cliente: eliminar `SyncSources`, modificar `InboxCubit.syncAndReload()` para invocar `sync-feeds` on-demand antes de `SyncUserData.execute()`, acotar el push de `SyncUserData` para artículos.
4. En el primer arranque post-deploy, cada dispositivo debe limpiar su box local de artículos (se reutiliza `clearAll()` ya existente) para no mezclar ids viejos con los nuevos.
5. Rollback: si algo falla, revertir el binario del cliente es seguro (sigue funcionando con `SyncSources` viejo) siempre que no se haya truncado `articles` todavía — por eso el truncado va al final de la migración SQL, no al principio.

## Open Questions

- ¿La función on-demand debería tener algún rate-limit básico (por ejemplo, no más de 1 invocación por usuario cada N segundos)? Se decidió no implementarlo ahora; revisar si se vuelve un problema real.
- Si en el futuro se necesita frescura sin depender de que el usuario abra la app (por ejemplo, para notificaciones push de artículos nuevos), habría que reconsiderar un cron baseline — la función ya está escrita para procesar un usuario a la vez con tope de fuentes, así que reintroducirlo sería agregar de nuevo el `cron.schedule` + secretos de Vault que se sacaron acá, no un rediseño.
