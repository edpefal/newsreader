## Context

`summarize-article/index.ts` define un prompt fijo por idioma en `INSTRUCTIONS` (es/en/fr), que hoy le pide a Gemini "en un párrafo" (o "in one paragraph" / "en un paragraphe") de forma literal, y refuerza esa idea con un par de ejemplos "MAL/BIEN" que muestran un único párrafo de salida. El `RESPONSE_SCHEMA` solo exige `summary: STRING`, sin restricción de estructura interna, así que un string con varios párrafos separados por `\n\n` ya es una respuesta válida hoy sin tocar el schema. En el cliente, `ArticleSummarySheetContent` (`article_summary_bottom_sheet.dart`) renderiza `summary.summary` con un `Text()` simple, que ya respeta saltos de línea.

## Goals / Non-Goals

**Goals:**
- Cambiar el texto de las instrucciones (es/en/fr) para permitir 1 a 4 párrafos, dejando 1 como comportamiento normal y justificando párrafos adicionales solo cuando el artículo tenga varios temas separables.
- Mantener la voz editorial (tono, gancho, "cuéntaselo a un amigo") igual en todos los párrafos.

**Non-Goals:**
- No se cambia `RESPONSE_SCHEMA` ni el shape de la respuesta HTTP.
- No se cambia ningún widget de Flutter ni el modelo Hive de persistencia.
- No se agrega ningún límite programático (validación de cantidad de párrafos en el backend); se confía en el prompt igual que hoy se confía en él para el tono y el largo de un párrafo.

## Decisions

- **Instrucción de rango en vez de conteo fijo**: cambiar "en un párrafo" por una instrucción tipo "normalmente en un párrafo; usa hasta un máximo de 4 solo si el artículo cubre varios temas o ideas separables que lo justifiquen". Alternativa descartada: pedir siempre "1 a 4 párrafos" sin indicar que 1 es el caso normal — se descarta porque el modelo tendería a expandir artículos simples innecesariamente, contradiciendo la meta original de un resumen breve.
- **Separador de párrafos**: pedir explícitamente que use un salto de línea en blanco (`\n\n`) entre párrafos dentro del mismo string, ya que así ya lo renderiza el `Text()` del bottom sheet sin cambios.
- **No tocar `RESPONSE_SCHEMA`**: como el campo sigue siendo un `STRING` libre, no hace falta modificar el schema de Gemini; el control de estructura queda enteramente en el texto de las instrucciones, igual que hoy controla el tono.
- **Actualizar los ejemplos MAL/BIEN**: se ajustan para no dar a entender que la salida siempre es un párrafo — se agrega una aclaración de que el ejemplo ilustra el tono, no una regla de longitud fija.
- **Aplicar el mismo cambio a los 3 idiomas (es/en/fr)** en paralelo, para no dejar comportamiento inconsistente entre locales.

## Risks / Trade-offs

- [Gemini podría abusar de los 4 párrafos incluso en artículos simples] → Mitigar dejando explícito en el prompt que 1 párrafo es el caso normal y que usar más requiere justificación (varios temas separables).
- [Cambio de prompt sin tests automatizados que verifiquen el número de párrafos, ya que depende del modelo] → Aceptado como riesgo conocido: no hay forma determinista de testear la salida de un LLM; se valida manualmente antes de deploy, igual que los cambios de tono previos a este prompt.
