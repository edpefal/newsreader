## Why

`article-mentions` hoy solo detecta libros/podcasts/música. Los artículos frecuentemente citan o linkean a otros artículos (otro newsletter, un paper, una nota de prensa) que hoy quedan invisibles en el resumen — el usuario tiene que ir al artículo original y buscar el link a mano.

## What Changes

- Nuevo tipo de mención `article` (URL de otro artículo mencionado/citado), sumado a los ya soportados (`book`, `podcast`, `music`).
- El contenido que se le manda a Gemini para generar el resumen deja de ser texto plano puro: se preserva cada link como `[texto del link](url)`, para que Gemini pueda detectar semánticamente qué links "cuentan" como un artículo mencionado/citado (a diferencia de navegación, redes sociales, o CTAs) — nueva utilidad de conversión, separada de `HtmlToPlainText` (que sigue usando `daily-summaries`, sin cambios).
- `summarize-article` extiende su detección de menciones para devolver, además de `{ type, name }`, un campo `url` cuando `type` es `article`.
- `enrich-mentions` extiende su enriquecimiento: para menciones de tipo `article`, hace un fetch a esa URL y extrae metadata Open Graph (`og:title`, `og:image`) en vez de consultar Google Books/iTunes Search.
- **Diferencia de comportamiento respecto a los demás tipos**: una mención de tipo `article` SIEMPRE es tappable (la URL ya es real, extraída directamente, no una búsqueda por nombre) — si el fetch de Open Graph falla o la página no tiene esos metadatos, la mención se muestra con el nombre que infirió Gemini pero sigue abriendo esa URL al tocarla, a diferencia de libro/podcast/música (donde sin match no hay link ni acción de tap).

## Capabilities

### Modified Capabilities
- `article-mentions`: agrega el tipo de mención `article` (URL de otro artículo mencionado), su mecanismo de detección (preservando links en el contenido enviado a la API de IA) y de enriquecimiento (fetch de Open Graph en vez de un proveedor de búsqueda por nombre), y el comportamiento distinto de "siempre tappable" para este tipo.

## Impact

- **Backend**: `summarize-article` (prompt + `RESPONSE_SCHEMA` + parseo de menciones) y `enrich-mentions` (nueva rama de resolución por tipo `article` con fetch + parseo de Open Graph) en `supabase/functions/`.
- **App**: nueva utilidad de conversión HTML→texto-con-links (separada de `HtmlToPlainText`); `MentionType` gana el valor `article`; `EnrichedMention`/`RawMention` y su (de)serialización; `MentionCard` y el bottom sheet deben distinguir el caso "siempre tappable sin imagen" de "sin match, no tappable".
- No afecta `daily-summaries` (sigue usando `HtmlToPlainText` sin cambios) ni el resto de `article-summaries`.
