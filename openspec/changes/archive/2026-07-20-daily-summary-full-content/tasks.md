## 1. Utilidad HTML → texto plano

- [x] 1.1 Crear `lib/core/utils/html_to_plain_text.dart` con una clase (siguiendo el patrón estático de `FeedContentChecker`) que reciba un `String` HTML y devuelva texto plano: remueve bloques `<script>`/`<style>` completos, reemplaza tags de bloque (`<br>`, `</p>`, `</div>`, `</tr>`, `</li>`, etc.) por saltos de línea, remueve el resto de los tags, decodifica entidades HTML comunes (`&amp;`, `&nbsp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`, numéricas `&#NNN;`), y colapsa espacios/líneas en blanco repetidas.
- [x] 1.2 Escribir tests unitarios en `test/unit/core/utils/html_to_plain_text_test.dart`: HTML simple con párrafos, HTML con `<script>`/`<style>` embebidos, entidades HTML, tags anidados/mal cerrados, string vacío, HTML sin ningún tag (texto plano tal cual), y un caso con estructura de tabla (similar al HTML real de newsletter visto en `email-to-rss-generated-feeds`).

## 2. Integración en GenerateDailySummary

- [x] 2.1 Modificar `lib/features/summaries/domain/usecases/generate_daily_summary.dart` para que, al armar cada `ArticleExcerpt`, use `FeedContentChecker.isTruncated(article.contentHtml)` para decidir: si NO está truncado, usar `HtmlToPlainText` sobre `article.contentHtml!`; si está truncado, usar `article.excerpt ?? ''` como hoy.
- [x] 2.2 Actualizar/agregar tests unitarios en `test/unit/features/summaries/domain/usecases/generate_daily_summary_test.dart` cubriendo: artículo con contenido completo (usa texto extraído de contentHtml), artículo truncado (usa excerpt), y artículo sin contentHtml (usa excerpt).

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` y resolver cualquier warning.
- [x] 3.2 Correr `flutter test` sobre los módulos nuevos/modificados y confirmar que todo pasa.
- [x] 3.3 Probar manualmente: generar un resumen diario real con al menos un artículo que tenga `contentHtml` completo, y confirmar que el párrafo resultante refleja contenido más allá del excerpt original. Verificado en emulador Android con un newsletter real de hoy: el resumen incluyó ~9 noticias distintas del mismo artículo (Meta/Anthropic, SpaceX/Pentágono, India Vikram-1, China, Claude Code, scroll-world, Apple/Nvidia, AWS, Qwen3.8), confirmando que se usó el contenido completo y no solo el excerpt.

## 4. Fixes encontrados al probar con más fuentes reales

- [x] 4.1 Corregir `HtmlToPlainText`: descartar entidades numéricas de surrogates UTF-16 aislados (0xD800–0xDFFF) en vez de emitirlas, evitando el crash `Invalid argument(s): string is not well-formed UTF-16` visto con un newsletter real. Test de regresión agregado en `html_to_plain_text_test.dart` (más un test de code point astral válido para no romper emojis legítimos).
- [x] 4.2 Agregar `AppConstants.summaryGenerationTimeout` (45s) y pasarlo explícitamente en `GeminiSummaryGenerator.summarize()`, en vez de heredar el default de `feedFetchTimeout` (10s) pensado para RSS. Evita `TimeoutException` al resumir varias fuentes con contenido completo. Test agregado en `gemini_summary_generator_test.dart` verificando el timeout usado.
- [x] 4.3 Subir `maxOutputTokens` de 2048 a 8192 en `supabase/functions/summarize-articles/index.ts` y desplegar. Evita que Gemini corte a mitad de oración el párrafo de la última fuente cuando hay muchas fuentes con contenido completo (verificado con 18 fuentes reales, antes y después del fix).
- [x] 4.4 Reverificar manualmente en el emulador con las mismas 18 fuentes: sin error de generación, y el último párrafo del resumen termina en una oración completa.
