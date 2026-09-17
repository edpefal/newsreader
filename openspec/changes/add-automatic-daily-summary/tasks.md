## 1. Migración: tabla `user_preferences`

- [x] 1.1 Crear migración con la tabla `user_preferences` (`user_id uuid primary key references auth.users (id) on delete cascade`, `locale text`, `utc_offset_minutes integer`, `updated_at timestamptz not null default now()`), siguiendo el mismo patrón de RLS que `entitlements` (el propio usuario lee/escribe su fila; `service_role` sin restricción).
- [x] 1.2 Agregar índice si hace falta para la consulta del cron por `updated_at` (mismo patrón que `articles_user_id_updated_at_idx`), solo si `SyncUserData` va a paginar esta tabla igual que las demás. (No hace falta: una sola fila por usuario, ya indexada por PK `user_id`; `SyncUserData` la sincroniza igual que las demás tablas vía `fetchChangedSince`, sin necesitar paginación adicional.)

## 2. Cliente: sincronizar `user_preferences`

- [x] 2.1 Agregar `UserPreferencesModel` (Hive) + datasource local, siguiendo el patrón de `NewsSourceModel`/`ArticleModel` (nuevo `typeId` de Hive, ver regla de ids reservados en CLAUDE.md — usar el siguiente disponible).
- [x] 2.2 Agregar `_syncUserPreferences()` a `SyncUserData` (`lib/features/sync/domain/usecases/sync_user_data.dart`), calculando el locale activo (`Localizations.localeOf` o equivalente ya usado por `AppLocalizations`) y el offset horario actual (`DateTime.now().timeZoneOffset.inMinutes`) en cada ciclo, y haciendo upsert incondicional (no depende de "changed since": es una sola fila pequeña por usuario, se reescribe siempre con el valor actual del dispositivo).
- [x] 2.3 Test unitario de `_syncUserPreferences()` (mock de `CloudSyncClient`) verificando que se hace upsert del locale y offset actuales en cada llamada a `SyncUserData.execute()`.

## 3. `sync-feeds`: modo background (freshness sin usuario)

- [x] 3.1 Modificar `supabase/functions/sync-feeds/index.ts` para aceptar un modo `{ "mode": "background" }` en el body, válido únicamente cuando el caller se autentica con `service_role` (no un JWT de usuario) — reutilizar la validación ya existente de token, agregando la rama de `service_role`. (Detección extraída a `background_mode.ts::isBackgroundInvocation` para poder testearla sin un cliente HTTP real.)
- [x] 3.2 En modo background, cambiar la consulta de fuentes: quitar el filtro `.eq("user_id", userId)`, mantener `is("deleted_at", null)`, `order("last_synced_at", ...)` y el mismo `limit(MAX_SOURCES_PER_INVOCATION)` — el resto de `syncSource()`/`mapWithConcurrency` no cambia.
- [x] 3.3 Tests de Deno para el modo background (`sync-feeds` no tiene tests hoy más allá de `url_safety_test.ts`; agregar cobertura mínima de que el modo background ignora `user_id` y respeta el tope, con un mock de Supabase client si el patrón de testing de la función lo permite razonablemente — si no, documentar la verificación manual en su lugar). (`background_mode_test.ts` cubre la detección del modo; la consulta real a Postgrest vía el admin client no se mockea — mismo alcance de testing que ya tenía `sync-feeds` antes de este change — se verifica manualmente contra el proyecto una vez desplegado, ver tarea 7.6.)
- [x] 3.4 Migración: `cron.schedule` invocando `sync-feeds` en modo background cada pocos minutos, vía `net.http_post` con `timeout_milliseconds` explícito (ver `centralize-feed-fetching`, migración `20260727020000`, para el valor de timeout que ya se probó suficiente) y las credenciales desde `vault.decrypted_secrets` (mismo patrón que el cron removido en `20260727230000`, reintroduciendo esos secretos de Vault).

## 4. Nueva Edge Function `generate-daily-summaries`

- [x] 4.1 Extraer las `VOICE_INSTRUCTIONS` y la lógica de armado de prompt de `supabase/functions/summarize-articles/index.ts` a un módulo compartido reutilizable por la nueva función, sin duplicar el texto de las instrucciones editoriales. (Extraídas a `generate-daily-summaries/prompt.ts`; de paso se corrigió voseo preexistente encontrado en el texto en español al moverlo, ver tarea 7.5.)
- [x] 4.2 Reutilizar `entitlement.ts` (consulta directa a `entitlements` con `service_role`, sin sesión en vivo) para el chequeo de suscripción activa.
- [x] 4.3 Adaptar `today_range.ts` (hoy calcula el rango "hoy" en UTC) para aceptar un offset horario en minutos y devolver el rango del día local de un usuario específico. (Renombrado a `local_day_range.ts::localDayRange`, con `todayUtcRange` conservada como caso particular de offset 0.)
- [x] 4.4 Implementar `generate-daily-summaries/index.ts`: para cada usuario con al menos una fuente, calcular su hora/fecha local desde `user_preferences` (default UTC+0 si no tiene fila), filtrar por umbral de hora local + sin `DailySummary` de hoy (local) + elegibilidad (`entitlements.is_active` o fecha local = lunes), y para cada uno generar el resumen leyendo artículos directo de Postgres (no de un request del cliente), persistiendo `DailySummary` + `sourceBlocks` igual que hoy hace `summarize-articles`.
- [x] 4.5 Tests de Deno para `generate-daily-summaries`: elegibilidad (suscripción activa cualquier día / sin suscripción solo lunes / sin suscripción otro día no elegible), idempotencia (usuario con `DailySummary` de hoy se omite), fallback de locale a inglés, uso del offset default (UTC+0) cuando no hay `user_preferences`. (`eligibility_test.ts`, `user_context_test.ts`, `language_test.ts`; la orquestación completa de `index.ts` contra Postgres/Gemini reales no se mockea, mismo alcance de testing que ya tenía `sync-feeds` — se verifica manualmente tras el deploy, ver tarea 7.6.)
- [x] 4.6 Migración: `cron.schedule` invocando `generate-daily-summaries` cada hora, mismo mecanismo de `net.http_post` + Vault que el modo background de `sync-feeds`.

## 5. Cliente: eliminar la generación manual de resumen diario

- [x] 5.1 Eliminar `GenerateDailySummary` (`lib/features/summaries/domain/usecases/generate_daily_summary.dart`) y sus excepciones (`NoArticlesTodayException`, `DailySummaryAlreadyGeneratedException`). (También se eliminó `SummaryGenerator`/`GeminiSummaryGenerator`, sin más callers tras esta eliminación.)
- [x] 5.2 Eliminar el flujo de generación de `SummariesCubit` (`generateTodaySummary()`, `_generate()`, el chequeo de cupo gratis, el disparo de paywall) y los campos de estado asociados (`canGenerateToday`, `alreadyGeneratedToday`) en `summaries_state.dart` que ya no correspondan a una pantalla de solo lectura.
- [x] 5.3 Actualizar `summaries_screen.dart` para quitar el botón "Crear resumen", el indicador de cupo gratis, y cualquier UI de paywall — la pantalla queda como lista + estado vacío únicamente (ver spec `daily-summaries`, requirement "Listado de resúmenes diarios", sin cambios).
- [x] 5.4 Eliminar `DailySummaryFreeUsageRepository`/`DailySummaryFreeUsageRepositoryImpl`, `DailySummaryFreeUsageLocalDataSource`/`HiveDailySummaryFreeUsageDatasource`, `DailySummaryFreeUsageModel`, `DailySummaryFreeUsageStatus`, y su registro en `core/di/injection.dart`.
- [x] 5.5 Eliminar la sincronización de `daily_summary_free_usage` en `SyncUserData` (`_syncDailySummaryFreeUsage`) y la tabla correspondiente en una migración (`drop table daily_summary_free_usage`).
- [x] 5.6 Actualizar/eliminar los tests existentes que cubrían el flujo manual (`SummariesCubit`, `GenerateDailySummary`, `DailySummaryFreeUsageRepositoryImpl`, etc.) acorde a lo eliminado.
- [x] 5.7 Revisar los 3 `.arb` (`app_en.arb`, `app_es.arb`, `app_fr.arb`) y eliminar las claves de texto que quedaron huérfanas (botón "Crear resumen", mensajes de cupo gratis, estados de error ligados al botón), corriendo `flutter gen-l10n` después.

## 6. Backend: retirar `summarize-articles` y el cupo gratis semanal

- [x] 6.1 Eliminar el endpoint HTTP de `summarize-articles` como invocable por cliente (o dejar el archivo solo si su lógica se sigue compartiendo como módulo con `generate-daily-summaries` desde ahí — decidir según cómo haya quedado la extracción de la tarea 4.1, evitando duplicar el prompt en dos archivos). (Toda la lógica reusable se movió a `generate-daily-summaries/`; se eliminó la carpeta `supabase/functions/summarize-articles/` completa, ya sin ningún caller.)
- [x] 6.2 Eliminar `free_usage.ts`/`free_usage_test.ts` de `supabase/functions/summarize-articles/` (o de donde haya quedado tras 4.1) — ya no hay cupo gratis semanal que chequear. (Eliminados junto con el resto de la carpeta en 6.1 — nunca se copiaron a `generate-daily-summaries/`.)
- [x] 6.3 Migración: eliminar el contador/función de `ai_usage_daily`... revisar si el cupo gratis semanal vivía en una tabla separada (`daily_summary_free_usage`, ya cubierta en 5.5) o en `ai_usage_daily` — si comparten tabla, solo eliminar las columnas/filas específicas del cupo gratis semanal, no la tabla completa (que sigue usándose para `article-summaries`). (Confirmado: vivía en la tabla separada `daily_summary_free_usage`, ya eliminada por completo en `20260916030000_drop_daily_summary_free_usage.sql`; `ai_usage_daily` no se toca.)

## 7. Verificación

- [x] 7.1 Correr `flutter analyze` sin warnings. (Sin issues.)
- [x] 7.2 Correr `flutter test` completo, confirmando que no quedan tests rotos por el código eliminado. (561/561 en verde.)
- [x] 7.3 Correr `flutter gen-l10n` después de tocar los `.arb` y confirmar que compila. (Corre sin error.)
- [x] 7.4 Correr `(cd supabase/functions/sync-feeds && deno test --allow-env)` y `(cd supabase/functions/generate-daily-summaries && deno test --allow-env)`. (13/13 y 47/47 respectivamente.)
- [x] 7.5 Revisar a mano (no hay test automático para esto) que el texto en español de cualquier prompt/instrucción movido o tocado en este change sigue en español neutro sin voseo (ver regla de CLAUDE.md sobre prompts embebidos en Edge Functions). (Se encontró y corrigió voseo preexistente — "Tratá"/"vos" — al mover `VOICE_INSTRUCTIONS.es` a `prompt.ts`; queda cubierto además por un test automático nuevo, `prompt_test.ts`, para que no vuelva a colarse. Migraciones SQL y comentarios en español revisados a mano, sin voseo.)
- [ ] 7.6 Confirmar con el usuario a cuál(es) proyecto(s) de Supabase (`reevo` prod / `reevo-dev`) desplegar las migraciones y las Edge Functions nuevas/modificadas antes de dar el change por terminado (ver CLAUDE.md).
- [x] 7.7 Correr `openspec validate add-automatic-daily-summary --strict`. ("Change 'add-automatic-daily-summary' is valid".)
