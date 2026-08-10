## Why

La pantalla de detalle de un resumen diario muestra `DailySummary.content` como un único bloque de texto plano, sin jerarquía visual ni forma de saltar al artículo original desde ahí. El resumen ya está organizado por fuente (un párrafo por fuente, prefijado con su nombre), pero eso no se refleja en la UI ni permite navegar a los artículos que lo generaron.

## What Changes

- `SummaryDetailScreen` parsea `DailySummary.content` en bloques (separados por línea en blanco, formato ya garantizado por el prompt existente) y muestra el nombre de la fuente de cada bloque en negrita.
- `GenerateDailySummary` persiste, junto al `content` de siempre, la agrupación por fuente que ya arma internamente antes de llamar a la IA (`sourceId`, `sourceName`, `articleIds` por fuente) — sin cambiar el prompt ni el backend de Gemini.
- `SummaryDetailScreen` empareja cada bloque parseado con su agrupación por nombre de fuente y, debajo del párrafo, muestra:
  - Un link directo al artículo si la fuente aportó un solo artículo ese día.
  - Una fila de chips (uno por artículo, título truncado) si aportó varios.
  - Nada, si no hay agrupación persistida para ese resumen (resúmenes generados antes de este cambio) o si ninguno de los artículos referenciados existe ya localmente (fuente eliminada después, cascade-delete).
- `DailySummaryModel` (Hive) agrega un campo opcional para esta agrupación — migración aditiva, sin tocar los resúmenes ya guardados.

## Capabilities

### New Capabilities

_(ninguna)_

### Modified Capabilities

- `daily-summaries`: el requirement "Generación de resumen diario del inbox" se amplía para persistir la agrupación por fuente junto al resumen. El requirement "Detalle de un resumen" se amplía para especificar el título en negrita y los links/chips a los artículos.

## Impact

- `lib/core/domain/entities/daily_summary.dart`
- `lib/core/data/models/daily_summary_model.dart` (+ regenerar `daily_summary_model.g.dart` vía `build_runner`)
- `lib/features/summaries/domain/usecases/generate_daily_summary.dart`
- `lib/features/summaries/presentation/screens/summary_detail_screen.dart`
- Tests unitarios de `generate_daily_summary` y widget de `summary_detail_screen`
