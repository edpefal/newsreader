## Context

Ver `proposal.md` para la motivación. Hoy `GenerateArticleSummary._articleContentFor` usa `HtmlToPlainText.convert`, que elimina todos los tags HTML incluidos los `<a href>` — cualquier link del artículo se pierde antes de llegar al prompt de `summarize-article`. `HtmlToPlainText` también la usa `GenerateDailySummary`, así que no se puede cambiar su comportamiento sin afectar el resumen diario.

`enrich-mentions` hoy resuelve `book`/`podcast`/`music` contra Google Books/iTunes Search por nombre (ver `providers.ts`); nunca hace fetch a una URL arbitraria provista por el cliente.

## Goals / Non-Goals

**Goals:**
- Detectar links a otros artículos dentro del contenido, distinguiéndolos semánticamente de navegación/redes sociales/CTAs (tarea que requiere criterio del LLM, no un parser determinístico).
- Enriquecer esas menciones con datos reales de Open Graph de la URL citada.
- Mantener intacto el comportamiento de `daily-summaries` (no toca `HtmlToPlainText`).

**Non-Goals:**
- No se resuelve el contenido del artículo citado (solo título + imagen de portada, no su texto).
- No se valida que la URL citada pertenezca a un feed que el usuario sigue — puede ser cualquier artículo externo.
- No se cachea el resultado de Open Graph entre distintos artículos que citen la misma URL (mismo no-goal que ya aceptó `article-mentions` para libros/podcasts/música).

## Decisions

### Nueva utilidad `HtmlToLinkedText`, no modificar `HtmlToPlainText`

Se agrega `core/utils/html_to_linked_text.dart` con el mismo criterio de limpieza que `HtmlToPlainText` (remueve `<script>`/`<style>`, decodifica entidades, colapsa espacios) pero reemplaza cada `<a href="URL">TEXTO</a>` por `[TEXTO](URL)` antes de remover el resto de los tags, en vez de perder el href. `GenerateArticleSummary._articleContentFor` pasa a usar esta utilidad; `GenerateDailySummary` no se toca.

Las URLs relativas (`href="/p/algo"`) SHALL resolverse a absolutas contra `article.articleUrl` antes de incluirse — si no, la URL que le llega a `enrich-mentions` no sería fetcheable.

### Prompt: Gemini identifica semánticamente qué link "cuenta" como mención

Se extiende la instrucción de `summarize-article` explicando el formato `[texto](url)` presente en el contenido, y pidiéndole a Gemini que identifique cuáles de esos links son artículos que el autor menciona/cita explícitamente (no links de "seguinos en Twitter", "suscribite", menús, o el propio dominio del artículo). Alternativa descartada: extraer todas las URLs con un parser HTML determinístico del lado de la app y mandárselas aparte a Gemini para que solo diga "sí/no es una mención" — se descartó porque separa la detección en dos pasadas sin necesidad; Gemini ya recibe el contexto completo del artículo en una sola llamada y puede aplicar el criterio semántico directamente sobre el texto con links inline.

`RESPONSE_SCHEMA` (`summarize-article/index.ts`) agrega `"article"` a `MENTION_TYPES` y un campo `url` (opcional en el schema; requerido en la práctica solo cuando `type: "article"`, validado en `mentions.ts` — un item de tipo `article` sin `url` válida se trata como respuesta inválida del modelo, igual que cualquier otro shape inesperado).

### `enrich-mentions`: nueva rama de resolución por Open Graph, sin nueva llamada a Gemini

`providers.ts` gana `resolveArticle(url, fetchImpl)`: hace `fetch(url)`, y extrae `og:title`/`og:image` del HTML de respuesta con una regex simple sobre `<meta property="og:title" content="...">` (y `og:image`), con fallback a `<title>` si no hay `og:title`. No se suma una dependencia de parsing de DOM completo (ej. deno-dom) para esto — el regex sobre `<meta>` es suficiente y evita el costo/superficie de una librería nueva para un caso acotado.

A diferencia de libro/podcast/música (donde sin match no hay `link`), para `type: "article"` el campo `link` de la respuesta de `enrich-mentions` SHALL setearse siempre a la URL original detectada, haya o no tenido éxito el fetch de Open Graph. Esto es la pieza clave que hace "siempre tappable" una consecuencia natural del contrato de datos, sin necesitar una rama de UI aparte: el bottom sheet/`MentionCard` ya deciden si algo es tappable en base a si `link != null`, no en base a si hay imagen.

### Fix necesario en el cliente: gating de tap por `link`, no por `imageUrl`

`MentionCard` hoy decide si es tappable con `hasImage = mention.imageUrl != null; onTap: hasImage ? onTap : null`. Para libro/podcast/música esto era equivalente a mirar `link` porque el proveedor siempre los devuelve juntos o ninguno. Con `article` dejan de ir siempre juntos (puede haber `link` sin `imageUrl`), así que el gating pasa a ser `mention.link != null ? onTap : null` — corrección de un acoplamiento implícito que ya no vale para el nuevo tipo, no un cambio de comportamiento visible para los tipos existentes.

### Seguridad: `enrich-mentions` pasa a hacer fetch de URLs no confiables (riesgo SSRF)

Ver Risks abajo.

## Risks / Trade-offs

- [Riesgo] `enrich-mentions` nunca había hecho fetch a una URL arbitraria provista indirectamente por contenido externo (el artículo, que viene de un feed RSS de un tercero) — esto abre una superficie de SSRF (Server-Side Request Forgery): un feed malicioso podría citar `http://169.254.169.254/...` u otra URL interna de la infraestructura de Supabase → Mitigación: validar que la URL detectada use esquema `http`/`https` y rechazar hosts que resuelvan a rangos de IP privados/loopback/link-local antes de hacer el `fetch`, devolviendo esa mención sin enriquecer (mismo tratamiento que una falla de fetch) en vez de un error que delate el chequeo.
- [Riesgo] Una página citada puede ser muy pesada o no responder → Mitigación: aplicar un timeout corto al fetch de Open Graph (igual de espíritu al `feedFetchTimeout` de 10s ya usado para RSS) y tratar el timeout como fetch fallido (mención sin enriquecer, con el link original igual).
- [Riesgo] Preservar links en el texto que recibe Gemini aumenta levemente el conteo de palabras contra `ai-usage-budget` (las URLs y la sintaxis `[]()` cuentan como "palabras" en el conteo simple por espacios) → Aceptado: el presupuesto diario tiene margen deliberado (ver `ai-usage-budget`), y no vale la complejidad de excluir URLs del conteo para este ahorro marginal.

## Migration Plan

No hay migración de datos: `RawMention`/`EnrichedMention` ganan un campo opcional (`url`), compatible con menciones ya persistidas de libro/podcast/música (quedan con `url: null`, sin impacto). Deploy: redesplegar `summarize-article` y `enrich-mentions` a dev y prod (mismo procedimiento que `add-article-summary-mentions`); no hay secrets nuevos (el fetch de Open Graph no requiere key).
