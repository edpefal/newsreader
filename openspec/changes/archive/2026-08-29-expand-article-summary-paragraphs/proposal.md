## Why

El prompt de `summarize-article` obliga a Gemini a resumir "en un párrafo", sin importar la extensión o complejidad del artículo original. Para artículos largos o con varios temas, un solo párrafo obliga a aplastar demasiada información y el resumen sale pobre o incompleto. Se necesita permitir que el modelo use hasta 4 párrafos cuando el artículo lo amerite, sin perder la voz editorial ni forzar longitud innecesaria en artículos simples.

## What Changes

- Actualizar las instrucciones (es/en/fr) de `summarize-article/index.ts` para permitir un resumen de 1 a 4 párrafos, usando más de uno solo cuando el artículo lo justifique (varios temas o ideas separables), y dejando 1 párrafo como el caso normal para artículos simples.
- Ajustar los ejemplos "MAL/BIEN" del prompt para que no impliquen que el resultado siempre es un único párrafo.
- Sin cambios de UI: el bottom sheet ya renderiza el `summary` como texto plano con `Text(summary.summary)`, que respeta saltos de línea (`\n\n` entre párrafos) sin requerir ningún cambio de widget.
- Sin cambios de contrato de API: `RESPONSE_SCHEMA` y el shape de la respuesta (`summary: string`) no cambian; solo cambia el contenido textual que puede incluir dentro del string.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `article-summaries`: el requirement de generación on-demand permite ahora que el resumen tenga hasta 4 párrafos cuando el artículo lo amerite, en vez de forzar siempre un único párrafo.

## Impact

- `supabase/functions/summarize-article/index.ts`: texto de `INSTRUCTIONS` (es/en/fr) y sus ejemplos.
- `openspec/specs/article-summaries/spec.md`: requirement de generación on-demand.
- Sin impacto en Flutter (`ArticleSummaryBottomSheet` ya soporta texto multi-párrafo).
- Sin impacto en el schema de respuesta de Gemini, ni en persistencia (Hive sigue guardando un `String summary`).
