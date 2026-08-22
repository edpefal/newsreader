## 1. Backend — tabla y función atómica de presupuesto

- [x] 1.1 Migración de Postgres: tabla `ai_usage_daily` (`user_id` PK, `day`, `words_used`, `updated_at`), RLS habilitado con policy `ai_usage_daily_select_own` (mismo patrón que `entitlements`), sin policy de insert/update para roles no privilegiados
- [x] 1.2 Migración de Postgres: función `check_and_record_ai_usage(p_words integer, p_daily_limit integer)` (`SECURITY DEFINER`, usa `auth.uid()` internamente), hace `INSERT ... ON CONFLICT` para crear la fila si no existe, resetea `words_used` a 0 si `day <> current_date`, y hace el chequeo-e-incremento en un único `UPDATE ... RETURNING (allowed, words_used)`
- [x] 1.3 Test SQL/manual de la función: verificar reset al cambiar de día, verificar que rechaza sin incrementar cuando excede el límite, verificar que dos llamadas concurrentes cerca del límite no permiten que la suma supere el límite (probado contra `reevo-dev` vía MCP; encontró y corrigió un bug real de columna ambigua en `check_and_record_ai_usage`)

## 2. Backend — aplicar el presupuesto en summarize-articles

- [x] 2.1 Extraer un contador simple de palabras (separar por espacios en blanco) a un archivo propio (ej. `word_count.ts`), sumando título + contenido de todos los artículos de la solicitud
- [x] 2.2 `index.ts`: antes de invocar a Gemini, llamar a `check_and_record_ai_usage` (vía `userClient.rpc`) con las palabras contadas y el límite diario (30,000); si `allowed = false`, responder con un error distinguible (ej. `{ error: "ai_usage_limit_reached" }`, status 429) sin invocar a Gemini
- [x] 2.3 Endpoint/consulta de estado de uso: confirmar que `ai_usage_daily` es legible por el cliente vía `CloudSyncClient.fetchChangedSince` bajo la RLS de 2.1 (sin necesidad de un edge function nuevo para lectura)
- [x] 2.4 Test Deno del contador de palabras (1.1) y de la extracción/armado del request a `check_and_record_ai_usage`

## 3. Cliente — AiUsagePolicy

- [x] 3.1 `core/ai_usage/ai_usage_policy.dart`: interfaz `AiUsagePolicy` con `Future<AiUsageStatus> getStatus()`, y la clase `AiUsageStatus` (`wordsUsed`, `wordLimit`, `resetsAt`)
- [x] 3.2 `core/ai_usage/supabase_ai_usage_policy.dart`: implementación que llama a `CloudSyncClient.fetchChangedSince('ai_usage_daily', null)` y arma el `AiUsageStatus` a partir de la fila devuelta (o un status en 0 si no hay fila todavía)
- [x] 3.3 Registrar `AiUsagePolicy` en `core/di/injection.dart` (único lugar que instancia `SupabaseAiUsagePolicy`)
- [x] 3.4 `core/errors/app_error_code.dart`: agregar `aiUsageLimitReached`; `core/errors/app_error_code_localizations.dart` y los 3 `.arb` (en/es/fr): agregar el mensaje localizado; correr `flutter gen-l10n`

## 4. Cliente — resumen diario consume el presupuesto

- [x] 4.1 `core/ai/gemini_summary_generator.dart`/`supabase_cloud_sync_client` (según corresponda): mapear la respuesta 429/`ai_usage_limit_reached` de `summarize-articles` a `SummaryGenerationException(AppErrorCode.aiUsageLimitReached)`
- [x] 4.2 `features/summaries/domain/usecases/generate_daily_summary.dart`: agregar `wouldRegenerateWithSameArticles()` — compara `countTodayArticles()` contra el `articleCount` del `DailySummary` de hoy ya guardado (si existe)
- [x] 4.3 `features/summaries/presentation/cubit/summaries_cubit.dart`: cargar `AiUsagePolicy.getStatus()` junto con el resto de `loadSummaries()`, exponerlo en `SummariesLoaded`
- [x] 4.4 `features/summaries/presentation/screens/summaries_screen.dart`: medidor visible del consumo (palabras usadas / límite), botón deshabilitado cuando el consumo alcanzó el límite
- [x] 4.5 `features/summaries/presentation/screens/summaries_screen.dart`: antes de llamar a `generateTodaySummary`, chequear `wouldRegenerateWithSameArticles()`; si es `true`, mostrar diálogo de confirmación y solo proceder si el usuario confirma
- [x] 4.6 Textos localizados nuevos (medidor, diálogo de confirmación) en los 3 `.arb`, correr `flutter gen-l10n`

## 5. Tests

- [x] 5.1 Fake/mock de `AiUsagePolicy` reutilizable en tests (`test/support/`)
- [x] 5.2 `test/unit/features/summaries/domain/usecases/generate_daily_summary_test.dart`: casos de `wouldRegenerateWithSameArticles` (mismo conteo, conteo distinto, sin resumen previo)
- [x] 5.3 `test/unit/features/summaries/presentation/cubit/summaries_cubit_test.dart`: actualizar para inyectar el mock de `AiUsagePolicy`, agregar casos del estado de uso cargado y expuesto
- [x] 5.4 `test/widget/features/summaries/summaries_screen_test.dart`: medidor visible con distintos estados de consumo, botón deshabilitado al agotar presupuesto, diálogo de confirmación (aparece cuando corresponde, confirmar dispara la generación, cancelar no la dispara)
- [x] 5.5 `test/unit/core/ai_usage/supabase_ai_usage_policy_test.dart`: verificar que arma `AiUsageStatus` correctamente a partir de la fila devuelta por `CloudSyncClient`, y el caso sin fila (usuario sin consumo previo)

## 6. Verificación final

- [x] 6.1 Correr `flutter analyze` y resolver cualquier warning
- [x] 6.2 Correr `flutter test` (unit + widget) y confirmar que todo pasa
- [x] 6.3 Probar manualmente: generar el resumen varias veces seguidas hasta acercarse/superar el límite diario (bajando temporalmente el límite en la función de Postgres para no tener que generar 30,000 palabras reales) y confirmar que el botón se deshabilita y el medidor refleja el consumo; probar la confirmación de "¿regenerar igual?" con y sin artículos nuevos — confirmado en dispositivo real
