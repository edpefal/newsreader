## 1. Backend (`supabase/functions/summarize-articles/`)

- [x] 1.1 Reemplazar el chequeo de `word_count.ts`/`ai_usage_budget` por un chequeo de "ya existe un `DailySummary` para (user_id, fecha de hoy server)" antes de invocar la API de IA
- [x] 1.2 Agregar (si no existe) una constraint de unicidad `(user_id, date)` sobre la tabla de `daily_summaries`, y manejar la violación de esa constraint como el nuevo error "resumen de hoy ya generado" en vez de dejarla propagarse como error genérico
- [x] 1.3 Responder con un código de error distinguible ("resumen de hoy ya generado") cuando ya existe un resumen de hoy, sin invocar la API de IA
- [x] 1.4 Correr los tests existentes de `summarize-articles` (`word_count_test.ts` deja de aplicar a esta función — mover/adaptar o eliminar según corresponda) y agregar test del nuevo chequeo de unicidad

## 2. Backend (`ai-usage-budget`, sin tocar `summarize-article` per-artículo)

- [x] 2.1 Confirmar que `supabase/functions/summarize-article/` (resumen por artículo, distinto de `summarize-articles`) sigue usando `ai_usage_budget` sin cambios
- [x] 2.2 No se requiere ningún cambio de código en `ai-usage-budget` en sí — la spec se angosta solo a nivel de documentación (delta spec ya escrita)

## 3. App Flutter — dominio y datos

- [x] 3.1 Revisar `GenerateDailySummary` (`lib/features/summaries/domain/usecases/generate_daily_summary.dart`): eliminar `wouldRegenerateWithSameArticles()` y cualquier lógica de regenerar; ajustar el flujo de generación para manejar el nuevo error "ya generado hoy"
- [x] 3.2 Revisar si `AiUsagePolicy`/`AppErrorCode` necesitan un código de error nuevo para "resumen de hoy ya generado", distinto del de presupuesto de palabras agotado (que sigue existiendo para `article-summaries`)

## 4. App Flutter — presentación

- [x] 4.1 `SummariesCubit`: eliminar `wouldRegenerateWithSameArticles`, quitar la dependencia de `AiUsagePolicy`/medidor de palabras del estado de esta pantalla si ya no aplica, agregar el estado "resumen de hoy ya generado" (booleano derivado de si existe `DailySummary` para hoy)
- [x] 4.2 `SummariesScreen`: eliminar `_confirmRegenerate` y el diálogo asociado, el botón "Regenerar resumen de hoy", y el medidor de consumo de palabras; agregar el nuevo indicador de "ya generado hoy" con el botón deshabilitado en ese estado
- [x] 4.3 Verificar que el flujo de paywall (mostrar Superwall si no hay suscripción, re-chequear tras compra) sigue intacto — no debería requerir cambios, pero confirmar que no dependía de nada eliminado

## 5. Internacionalización (los 3 `.arb`, mismo change)

- [x] 5.1 Eliminar `summariesRegenerateTodayButton`, `summariesRegenerateConfirmTitle`, `summariesRegenerateConfirmBody`, `summariesRegenerateConfirmButton` de `app_en.arb`, `app_es.arb`, `app_fr.arb` (también `summariesUsageMeter`, huérfana tras eliminar el medidor)
- [x] 5.2 Agregar la clave nueva para el indicador de "ya generado hoy" en los 3 `.arb`, en español neutro con tuteo (ver `neutral_spanish_test.dart`)
- [x] 5.3 Correr `flutter gen-l10n` tras los cambios de `.arb`

## 6. Verificación final

- [x] 6.1 `flutter analyze` sin warnings
- [x] 6.2 `flutter test` — actualizar/eliminar tests que referencien regenerar, el medidor de palabras, o `wouldRegenerateWithSameArticles`
- [x] 6.3 Confirmar manualmente (el usuario, en simulador) el flujo completo: generar el resumen de hoy, verificar que el botón queda deshabilitado con el indicador correcto, y que `article-summaries` (resumen por artículo) sigue funcionando sin cambios
