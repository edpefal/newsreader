## Why

El resumen diario hoy comparte el presupuesto de 30,000 palabras/día de `ai-usage-budget` con el resumen por artículo individual (`article-summaries`/`article-mentions`). Ese modelo es difícil de comunicar al usuario ("¿cuántas palabras me quedan?") y permite un uso ilimitado de regeneraciones del resumen diario mientras alcance el presupuesto compartido. Se decidió, tras explorar y descartar un approach de generación automática programada (inviable sin notificaciones push, que el PRD declara explícitamente fuera de alcance — sección 8), reemplazar ese gate por un límite simple y predecible: **una sola generación del resumen diario por día**, manteniendo el trigger manual que ya existe.

## What Changes

- El resumen diario deja de consumir ni chequear el presupuesto compartido de `ai-usage-budget`. En su lugar, el backend de `daily-summaries` rechaza una segunda generación el mismo día de servidor, sin importar palabras.
- **BREAKING (de producto, no de datos):** desaparece la funcionalidad de "Regenerar resumen de hoy". Una vez generado el resumen del día, el botón queda deshabilitado hasta el día siguiente — no hay forma de volver a generarlo ese mismo día aunque lleguen artículos nuevos.
- Como consecuencia, el diálogo de confirmación "¿Regenerar igual?" (para cuando no hay artículos nuevos desde la última generación) deja de tener sentido y se elimina junto con su lógica.
- El medidor de "palabras consumidas hoy / límite diario" en la pantalla de Resúmenes se reemplaza por un indicador simple: si el resumen de hoy ya fue generado o no.
- `article-summaries` y `article-mentions` (resumen por artículo individual) no se tocan — siguen usando el presupuesto compartido de `ai-usage-budget` exactamente como hoy.
- El modelo de datos no cambia: sigue existiendo como máximo un `DailySummary` por fecha.

## Capabilities

### Modified Capabilities
- `daily-summaries`: el gate de generación pasa de "presupuesto compartido de palabras" a "una generación por día de servidor"; se elimina la funcionalidad de regenerar y su diálogo de confirmación; el medidor de consumo de IA se reemplaza por un indicador de "ya generado hoy".
- `ai-usage-budget`: su alcance se angosta explícitamente a `article-summaries`/`article-mentions` — `daily-summaries` deja de ser una de las features cubiertas por este presupuesto.

## Impact

- `supabase/functions/summarize-articles/` (Edge Function del resumen diario): reemplaza el chequeo de `ai-usage-budget`/`word_count.ts` por un chequeo de "ya se generó hoy" contra la tabla de resúmenes.
- `supabase/functions/summarize-article/` (resumen por artículo): sin cambios.
- `lib/features/summaries/presentation/cubit/summaries_cubit.dart` y `summaries_screen.dart`: se elimina la lógica y UI de regenerar (`wouldRegenerateWithSameArticles`, diálogo de confirmación, botón "Regenerar"), se reemplaza el medidor de palabras por un indicador de estado "ya generado hoy".
- `lib/l10n/app_en.arb`, `app_es.arb`, `app_fr.arb`: se eliminan las claves de regenerar (`summariesRegenerateTodayButton`, `summariesRegenerateConfirmTitle`, `summariesRegenerateConfirmBody`, `summariesRegenerateConfirmButton`) y se agrega una nueva clave para el indicador de "ya generado hoy".
- Sin cambios en el modelo de datos (`DailySummary` sigue igual) ni en `article-summaries`/`article-mentions`.
