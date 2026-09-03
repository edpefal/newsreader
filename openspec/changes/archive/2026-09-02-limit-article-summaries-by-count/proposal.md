## Why

El presupuesto diario de IA de `article-summaries`/`article-mentions` hoy se mide en palabras (30,000/día), una unidad que el usuario no puede predecir: nadie sabe cuántas palabras tiene el artículo que está por resumir, así que el bloqueo se siente arbitrario cuando ocurre, y hoy ocurre sin ningún aviso previo — el usuario recién se entera con un error genérico al tocar el botón. Un análisis de la data real de artículos en producción (2,556 artículos con contenido) muestra que una unidad contable ("N resúmenes por día") preserva el mismo techo de costo aproximado y es mucho más fácil de comunicar y de mostrar de forma proactiva.

## What Changes

- Reemplazar el presupuesto diario de 30,000 palabras por un límite contable de **25 resúmenes de artículo por día por usuario**. Cada resumen generado (incluyendo la detección de menciones que viaja en el mismo request) cuenta como 1 unidad. **BREAKING**: cambia la unidad y el nombre de la columna que registra el consumo (`words_used` → conteo de resúmenes) en `ai_usage_daily`.
- Agregar un techo de **8,000 palabras por artículo individual**: si el contenido de un artículo supera ese umbral, el backend rechaza generar su resumen automático sin invocar a la API de IA (afecta a <0.3% de los artículos reales). Es un error distinto al de límite diario alcanzado.
- El cliente Flutter sincroniza `ai_usage_daily` (patrón `CloudSyncClient` ya usado por `sources`/`articles`/`daily_summaries`) para poder mostrar el consumo sin depender de que la solicitud falle primero.
- El bottom sheet de resumen de artículo:
  - No muestra ningún indicador mientras queden 6 o más resúmenes disponibles hoy.
  - Muestra un pill informativo ("Quedan N hoy") cuando quedan 5 o menos, en tono neutro (nunca el ámbar de acento, reservado a no-leído/favorito).
  - Muestra un estado propio y neutro (no el bloque rojo de error genérico) cuando se alcanzó el límite diario, con copy explicando cuándo se resetea.
- Nuevos `AppErrorCode` para "límite diario de resúmenes alcanzado" y "artículo demasiado largo para resumir", cada uno con sus 3 traducciones (en/es/fr).

## Capabilities

### New Capabilities

(ninguna — este change modifica capabilities existentes, no introduce una nueva)

### Modified Capabilities

- `ai-usage-budget`: la unidad del presupuesto pasa de palabras de input consumidas a cantidad de resúmenes generados (25/día), y se agrega un requirement nuevo de techo de longitud por artículo individual (8,000 palabras) como salvaguarda de costo independiente del contador diario.
- `article-summaries`: el requirement de generación on-demand pasa a referenciar el límite contable en vez del presupuesto de palabras; se agrega el rechazo por artículo demasiado largo; se agrega la presentación del indicador de uso restante y del estado neutro de límite alcanzado en el bottom sheet.

## Impact

- **Supabase**: migración que altera `ai_usage_daily` (columna de conteo en vez de palabras) y `check_and_record_ai_usage` (o su reemplazo) para operar sobre conteo con lock atómico + reset diario, igual que hoy. Edge function `summarize-article/index.ts` y `word_count.ts` (nuevo chequeo de 8,000 palabras por artículo antes de invocar a Gemini). Desplegar a confirmar con el usuario: `reevo` (prod) y/o `reevo-dev`.
- **Flutter**: `lib/core/data/datasources/local/` y `CloudSyncClient` (sync de `ai_usage_daily`), `lib/features/article_summary/presentation/` (bottom sheet: nuevo pill, nuevo estado de límite en el `switch` de `ArticleSummaryState`), `lib/core/errors/app_error_code.dart` (2 códigos nuevos), `lib/l10n/*.arb` (3 idiomas), `lib/core/ai/gemini_article_summary_generator.dart` (mapeo de los nuevos códigos de error del backend).
- **Specs**: `openspec/specs/ai-usage-budget/spec.md`, `openspec/specs/article-summaries/spec.md`.
