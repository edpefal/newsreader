## Why

El resumen diario hoy es informativo pero parco: el prompt de `summarize-articles` le indica a Gemini un "Formato de salida EXACTO" que prohíbe explícitamente encabezados, introducciones y cualquier desvío del texto factual. El resultado no engancha al usuario ni da ganas de volver todos los días. Con el contenido completo por artículo (change anterior `daily-summary-full-content`) ya hay material de sobra para darle personalidad al resumen sin perder sustancia.

## What Changes

- El prompt de `summarize-articles` pasa de pedir un párrafo factual neutro por fuente a pedir una voz narrativa consistente: tono "business-casual" (ingenioso pero no cursi, cercano pero no condescendiente), en español latinoamericano neutro (tuteo), inspirado en el estilo editorial de newsletters tipo Morning Brew.
- La voz es única y consistente para toda la app, aplicada por igual sin importar el tono original de cada fuente (no se adapta el tono al newsletter que se está resumiendo).
- Sin emojis: la personalidad viene del tono, el gancho de apertura de cada bloque, y el ritmo de las oraciones — no de decoración visual.
- Se agregan 1-2 ejemplos de referencia (few-shot) dentro del prompt para calibrar consistencia día a día, en vez de depender solo de una descripción abstracta del tono.
- Fuera de alcance explícito: cambiar la agrupación de "por fuente" a "por tema/noticia" (se mantiene 1 bloque por fuente); agregar renderizado enriquecido (markdown/negrita) en `SummaryDetailScreen` (sigue siendo `Text` plano); cualquier cambio en la estructura de datos de `DailySummary` o en el cliente Flutter.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `daily-summaries`: el requirement de generación de resumen diario cambia de "un párrafo breve factual por fuente" a "un párrafo con voz/personalidad consistente por fuente, sin emojis, en español neutro".

## Impact

- `supabase/functions/summarize-articles/index.ts`: reescritura de `buildPrompt()` únicamente. Sin cambios en la firma del request/response (sigue devolviendo `{ summary: string }`).
- Sin cambios en `lib/` (cliente Flutter): `GenerateDailySummary`, `GeminiSummaryGenerator`, `SummaryDetailScreen` quedan igual — `content` sigue siendo un string opaco.
- Sin cambios en el modelo de datos (`DailySummary`, Hive) ni en la sincronización de artículos.
