## Context

`summarize-articles/index.ts` arma el prompt vía `buildPrompt()` (ver `openspec/changes/archive/*-daily-summary-full-content/` para el change que hizo que el contenido de entrada dejara de ser un excerpt corto y pasara a ser el texto completo del artículo). El prompt actual es deliberadamente rígido:

> "Formato de salida EXACTO, sin desviarte... No agregues encabezados, introducciones, listas ni texto fuera de ese formato."

Esto se escribió originalmente para garantizar un output parseable y predecible (1 línea de fuente + 1 párrafo, separado por líneas en blanco), pero como efecto secundario mata cualquier posibilidad de personalidad. El usuario quiere un tono más parecido al de newsletters como Morning Brew: business-casual, ingenioso, con voz propia — sin volverse cursi ni forzado.

Restricciones ya establecidas en la exploración:
- Se mantiene la agrupación por fuente (1 bloque por fuente), no por tema.
- Sin emojis.
- Una sola voz consistente para toda la app, sin adaptar el tono a cada fuente.
- Español latinoamericano neutro, tuteo (convención ya establecida en todo el proyecto).
- `SummaryDetailScreen` sigue renderizando `content` como `Text` plano — el formato de salida (fuente + línea en blanco + bloque) debe seguir siendo el mismo para que el rendering actual no se rompa.

## Goals / Non-Goals

**Goals:**
- Reescribir `buildPrompt()` para pedir una voz con personalidad, manteniendo el mismo contrato de formato (fuente en una línea, párrafo en la(s) siguiente(s), línea en blanco entre fuentes).
- Calibrar el tono con guías explícitas de qué SÍ y qué NO (para evitar humor forzado o inconsistente día a día) y 1-2 ejemplos de referencia (few-shot) en español neutro.
- Mantener el mismo contrato de request/response de la edge function — cero cambios en el cliente Flutter.

**Non-Goals:**
- No se cambia la agrupación por fuente a agrupación por tema/noticia.
- No se agrega markdown, negrita, ni ningún renderizado enriquecido en el cliente.
- No se mide ni testea automáticamente "qué tan divertido" es el resultado — la calidad del tono se valida por lectura humana, no por asserts.
- No se toca `maxOutputTokens` (8192, ya ajustado en el change anterior) salvo que la verificación manual muestre que la voz con más personalidad produce bloques sustancialmente más largos.

## Decisions

### Estructura del nuevo prompt
Se reemplaza el bloque de instrucciones actual por uno que:
1. Define el rol/voz: "Escribís como alguien con onda que sabe de qué habla — pensá en el tono de un newsletter de noticias con personalidad (tipo Morning Brew), pero en español latinoamericano neutro, con tuteo."
2. Da guías explícitas de calibración (qué SÍ / qué NO), por ejemplo:
   - SÍ: una frase gancho o de contexto para abrir cada bloque, antes de entrar en los hechos.
   - SÍ: alguna observación o giro propio cuando aporte, sin inventar datos que no estén en el contenido.
   - NO: chistes forzados, exclamaciones en exceso, ni un tono "vendedor".
   - NO: emojis.
   - NO: cambiar el tono según la fuente — la voz es siempre la misma.
3. Mantiene intacta la regla de formato de salida (nombre de fuente en una línea, párrafo en la siguiente, línea en blanco entre fuentes) — esto es lo único que NO puede aflojarse, porque el cliente no parsea nada pero un formato consistente es lo que hace legible el resultado.
4. Incluye 1-2 ejemplos de referencia (few-shot) mostrando el ANTES (factual, plano) y el DESPUÉS (con voz) para el mismo contenido, en español neutro. Esto calibra mucho mejor que una descripción abstracta del tono — es el mecanismo real de consistencia día a día.

**Alternativa considerada**: describir el tono solo con adjetivos ("sé ingenioso, casual, con personalidad") sin ejemplos concretos. Se descarta como único mecanismo porque es la receta típica para un output inconsistente (algunos días forzado, otros de vuelta plano) — los ejemplos few-shot son el ancla real.

### Una sola voz, no adaptada por fuente
El prompt aclara explícitamente que la voz no cambia según el tipo de newsletter que se esté resumiendo (financiero, cultura, tech, etc.) — es la app la que tiene personalidad, no un espejo del tono de cada fuente. Esto es intencional: es lo que hace reconocible un estilo editorial consistente, como en Morning Brew.

### Sin cambios en el contrato técnico
`buildPrompt()` sigue recibiendo el mismo `ArticleExcerpt[]` (title, excerpt, sourceName) y devolviendo un string con el mismo formato de salida. No hay cambios en `GeminiSummaryGenerator`, `GenerateDailySummary`, ni en `SummaryDetailScreen`. El cambio es puramente de contenido del prompt.

## Risks / Trade-offs

- **[Riesgo] El tono puede sentirse forzado o "cringe" en algunos días** → Mitigación: las guías explícitas de qué NO hacer (no chistes forzados, no exclamaciones en exceso) más los ejemplos few-shot buscan minimizar esto, pero no hay garantía formal — se valida con lectura manual real, no con tests automáticos. Si el resultado no convence tras la verificación manual, se ajustan las guías del prompt antes de dar el change por cerrado.
- **[Riesgo] Con voz más elaborada, los bloques pueden crecer y acercarse de nuevo al límite de `maxOutputTokens` (8192)** → Mitigación: verificar manualmente con un día de muchas fuentes (similar al caso de 18 fuentes usado para validar el change anterior) que el resumen no se corta a mitad de oración.
- **[Trade-off] Calibrar el humor en español neutro es más difícil que en inglés** (mucho del humor de newsletters como Morning Brew depende de modismos/cultura pop en inglés que no traducen directo) → Se acepta un tono más sobrio que el original en inglés (ingenio conversacional antes que chistes o referencias culturales específicas), priorizando que suene natural en español neutro por sobre imitar literalmente el humor de la referencia.

## Migration Plan

Sin migración de datos ni cambios de contrato: se reescribe `buildPrompt()`, se despliega la edge function (`supabase functions deploy summarize-articles`), y se verifica generando un resumen real. Si el tono no convence, se puede iterar el prompt y redesplegar sin ningún otro cambio — no hay rollback de datos involucrado.
