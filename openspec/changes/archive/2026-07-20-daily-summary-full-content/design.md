## Context

`GenerateDailySummary` arma, para cada artículo del inbox publicado hoy, una tupla `(title, excerpt, sourceName)` que se manda tal cual a `summarize-articles` (edge function de Supabase que arma el prompt agrupado por fuente y llama a Gemini). Hoy `excerpt` viene directo de `Article.excerpt` (el `<description>`/`<summary>` crudo del feed RSS, sin garantía de longitud ni de estar libre de HTML).

`Article.contentHtml` ya está disponible localmente (sincronizado por `SyncSources`, persistido en Hive) y suele contener el cuerpo real de la noticia. El proyecto no tiene hoy ninguna utilidad de HTML → texto plano: `flutter_widget_from_html` (usado por `HtmlContentRenderer`) renderiza HTML a widgets, no extrae texto.

Un caso real ya observado (verificación manual del change `email-to-rss-generated-feeds`): el HTML de un newsletter puede traer tablas de layout, estilos inline, y URLs de tracking larguísimas dentro de atributos `href`/`src` — ruido irrelevante para un resumen de texto.

## Goals / Non-Goals

**Goals:**
- Extraer texto plano legible de `contentHtml` en el cliente, sin agregar una dependencia nueva de parsing HTML.
- Mantener el fallback a `excerpt` para artículos truncados (mismo criterio que `FeedContentChecker.isTruncated`).
- No tocar `summarize-articles` ni el contrato de `SummaryGenerator`/`ArticleExcerpt` — el cambio es enteramente de qué texto arma `GenerateDailySummary`.

**Non-Goals:**
- No se busca una extracción "perfecta" tipo Readability (identificar y descartar navegación, pies de página, etc.) — solo remover markup y quedarnos con el texto visible.
- No se trunca ni limita la longitud del texto extraído (decisión explícita: se manda completo).
- No se cambia el resumen a ser por artículo individual; sigue siendo el resumen diario agrupado por fuente.

## Decisions

### Extracción de texto: regex, no un parser DOM completo
Se implementa `HtmlToPlainText` (o nombre similar) en `core/utils/` con un enfoque basado en expresiones regulares:
1. Remover por completo los bloques `<script>...</script>` y `<style>...</style>` (contenido no visible/no textual).
2. Reemplazar tags de bloque comunes (`</p>`, `<br>`, `</div>`, `</tr>`, etc.) por un salto de línea, para no pegar palabras de párrafos/celdas distintas.
3. Remover el resto de los tags HTML.
4. Decodificar entidades HTML comunes (`&amp;`, `&nbsp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`, y entidades numéricas `&#NNN;`).
5. Colapsar espacios en blanco repetidos y líneas vacías múltiples.

**Alternativa considerada**: agregar el paquete `html` (parser DOM de dart.dev) y usar `document.body?.text`. Se descarta por ahora: es una dependencia nueva para un caso de uso acotado, y el enfoque regex ya cubre lo necesario sin abrir la puerta a tener que abstraerla según la tabla de `CLAUDE.md` (ninguna librería de terceros se importa fuera de su abstracción). Si en el futuro se necesita extracción más precisa (ej. para el resumen por artículo, fuera de alcance acá), se puede reevaluar.

### Dónde se aplica el fallback a excerpt
`GenerateDailySummary` ya tiene acceso a `FeedContentChecker` (mismo criterio usado por el Reader para decidir modo texto vs WebView). Se reutiliza tal cual: `FeedContentChecker.isTruncated(article.contentHtml)` decide si se usa `excerpt` o el texto extraído de `contentHtml`.

### Sin límite de longitud
Se manda el texto completo extraído sin cap. Es una decisión explícita del usuario, sabiendo que `gemini-2.5-flash` tiene ventana de contexto amplia y que el request sigue siendo 1 sola llamada agrupando todas las fuentes del día (limitación real: cuota de 20 req/día del free tier, no tokens). Si en el futuro se detecta que un newsletter puntual domina el prompt y degrada el resumen de las demás fuentes, se puede revisar como un change separado.

## Risks / Trade-offs

- **[Riesgo] Un artículo con HTML inusualmente extenso o mal formado infla el prompt o produce texto con ruido residual** → Mitigación: ninguna automática por decisión explícita (sin cap). Si se vuelve un problema real y observable, es un change futuro acotado (agregar límite de caracteres), no bloquea esta implementación.
- **[Riesgo] La extracción por regex puede fallar en casos borde de HTML muy irregular (tags mal cerrados, comentarios `<!-- -->` con contenido, CDATA)** → Mitigación: cobertura de tests unitarios con casos reales (incluyendo el HTML de newsletter verificado en el change anterior) para validar que el resultado es texto razonable, no una excepción. El resumen sigue funcionando aunque el texto extraído tenga algo de ruido residual — no es un requisito de precisión perfecta.
- **[Trade-off] No usar un parser DOM real** → Se acepta menor robustez a cambio de no sumar una dependencia nueva ni una abstracción adicional para un caso de uso de un solo consumidor.

### Hallazgos de la verificación manual con datos reales (post-implementación)

Tres problemas reales aparecieron al probar con más fuentes/artículos reales que en el desarrollo inicial, no previstos en las Decisions originales:

- **[Bug] Entidades HTML numéricas de surrogates UTF-16 aislados crasheaban la extracción** → Algunos feeds mal codificados emiten un emoji como dos entidades numéricas separadas (`&#55357;&#56960;` en vez de una sola `&#128640;`), cada una un surrogate suelto. `String.fromCharCode` no valida esto y produce un string mal formado que rompe más adelante al serializar el request (`Invalid argument(s): string is not well-formed UTF-16`), tumbando la generación completa del resumen. **Corregido**: `HtmlToPlainText` descarta code points en el rango de surrogates (0xD800–0xDFFF) en vez de emitirlos, con test de regresión.
- **[Riesgo materializado] El timeout heredado de `feedFetchTimeout` (10s) era insuficiente** → `GeminiSummaryGenerator` no pasaba un `timeout` explícito a `HttpClient.post`, heredando el default pensado para fetch de feeds RSS. Con contenido completo de varias fuentes, la llamada a Gemini supera los 10s y el request corta con `TimeoutException`, mostrando el error genérico "No se pudo generar el resumen" sin indicar la causa real. **Corregido**: nueva constante `AppConstants.summaryGenerationTimeout` (45s), pasada explícitamente, con test que verifica que se usa un timeout mayor al de fetch de feeds.
- **[Riesgo materializado] `maxOutputTokens: 2048` en `summarize-articles` se quedaba corto** → Con contenido completo (no excerpt) y varias fuentes, Gemini genera párrafos más largos y detallados por fuente; con muchas fuentes (verificado con 18), la suma supera 2048 tokens de salida y la última fuente se corta a mitad de oración (`finishReason: MAX_TOKENS`). **Corregido**: subido a 8192, desplegado y reverificado con las mismas 18 fuentes — el último párrafo ahora termina en una oración completa.

Los tres se verificaron end-to-end en un emulador Android con datos reales (múltiples newsletters sincronizados, hasta 18 artículos en un mismo resumen), no solo con tests unitarios.

## Migration Plan

Sin migración de datos: no cambia el modelo de `Article` ni `DailySummary`. El cambio es puramente en la construcción del payload que ya se envía a `summarize-articles`. Se puede desplegar y probar directamente generando un resumen diario nuevo.
