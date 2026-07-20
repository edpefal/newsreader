## Why

El resumen diario hoy se genera solo a partir del `excerpt` de cada artículo (el `<description>` crudo del feed), que muchas veces es corto, está vacío, o solo repite el título. El resultado es un resumen superficial que no refleja el contenido real de las noticias del día. Los artículos ya traen el HTML completo (`contentHtml`) sincronizado localmente — usarlo da un resumen mucho más informativo sin ningún costo adicional de red o sincronización.

## What Changes

- `GenerateDailySummary` arma el `ArticleExcerpt` de cada artículo con texto plano extraído de `contentHtml` (limpiando HTML a texto en el cliente), en vez de `excerpt`, cuando el artículo tiene contenido completo real.
- Nueva utilidad en `core/` que convierte HTML a texto plano (sin agregar una librería de terceros nueva), siguiendo el mismo patrón que `FeedContentChecker`.
- Artículos con `contentHtml` truncado o vacío (mismo criterio que ya usa `FeedContentChecker.isTruncated`: null o menor a 500 caracteres) siguen usando `excerpt` como fallback, igual que hoy.
- Sin límite de longitud por artículo: se manda el texto completo extraído, sin truncar.
- Sin cambios en `summarize-articles` (la edge function de Supabase): sigue recibiendo `{ title, excerpt, sourceName }` por artículo; solo cambia qué valor arma el cliente para el campo `excerpt` del payload.
- Fuera de alcance: resumen individual por artículo (esto es exclusivamente sobre el resumen diario agrupado por fuente que ya existe).

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `daily-summaries`: el requirement "Generación de resumen diario del inbox" cambia de "a partir del título y excerpt" a "a partir del título y el contenido completo del artículo (o excerpt como fallback si no hay contenido completo)".

## Impact

- `lib/features/summaries/domain/usecases/generate_daily_summary.dart`: arma el `ArticleExcerpt` con texto limpio de `contentHtml` en vez de `excerpt` directamente.
- `lib/core/utils/`: nueva utilidad de conversión HTML → texto plano.
- Sin cambios en `lib/core/ai/summary_generator.dart`, `lib/core/ai/gemini_summary_generator.dart`, ni en `supabase/functions/summarize-articles/`.
- Sin cambios en el modelo de datos (Hive) ni en la sincronización de artículos.
