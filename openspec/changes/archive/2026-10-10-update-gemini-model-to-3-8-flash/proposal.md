## Why

Google deprecó `gemini-3.7-flash` y redirige automáticamente todo su tráfico a `gemini-3.8-flash` (aviso por correo, sin acción obligatoria y con el mismo precio promocional). Hoy dos Edge Functions tienen el modelo escrito como constante; seguir apuntando al modelo deprecado depende de una redirección que Google puede retirar, y deja sin control en qué modelo corre realmente cada resumen.

## What Changes

- `supabase/functions/summarize-article/index.ts`: `GEMINI_MODEL` pasa de `gemini-3.7-flash` a `gemini-3.8-flash`.
- `supabase/functions/generate-daily-summaries/index.ts`: ídem.
- Despliegue de ambas funciones a `reevo-dev` y, tras verificar allí, a `reevo` (prod).
- Sin cambios de comportamiento esperados: mismos prompts, mismo `generationConfig`, mismos límites y mismo precio. No toca el cliente Flutter.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

Ninguna. Ningún spec nombra el modelo (`article-summaries`, `daily-summaries` y `ai-usage-budget` describen el comportamiento, no la versión), así que el change declara `skip_specs: true`.

## Impact

- Código: dos constantes en dos Edge Functions (Deno/TypeScript).
- Servidor: requiere desplegar `summarize-article` y `generate-daily-summaries` a los dos proyectos de Supabase.
- Costo: sin cambio según el aviso de Google ($0,75 / 1M tokens de entrada, $3,75 / 1M de salida, con 50 % de descuento promocional).
- Riesgo principal: que `gemini-3.8-flash` trate distinto algún parámetro de `generationConfig` (ver design.md).
