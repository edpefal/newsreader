## 1. App: preservar links en el contenido enviado a la API de IA

- [x] 1.1 Crear `core/utils/html_to_linked_text.dart` (`HtmlToLinkedText.convert`): mismo criterio de limpieza que `HtmlToPlainText`, pero reemplaza `<a href="URL">TEXTO</a>` por `[TEXTO](URL)` antes de remover el resto de los tags
- [x] 1.2 Resolver URLs relativas de los `href` contra `article.articleUrl` antes de emitir el markdown-link
- [x] 1.3 Unit tests de `HtmlToLinkedText` (links absolutos, relativos, anidados dentro de otros tags de bloque, artículo sin links)
- [x] 1.4 Cambiar `GenerateArticleSummary._articleContentFor` para usar `HtmlToLinkedText` en vez de `HtmlToPlainText` (sin tocar `GenerateDailySummary`)

## 2. Backend: `summarize-article` detecta menciones de tipo `article`

- [x] 2.1 Sumar `"article"` a `MENTION_TYPES` en `summarize-article/mentions.ts`; agregar campo `url` opcional a `RawMention` y a `RESPONSE_SCHEMA`
- [x] 2.2 Extender `parseMentions` para exigir `url` (string no vacía) cuando `type === "article"`, tratando su ausencia como respuesta inválida del modelo
- [x] 2.3 Extender el prompt (los 3 idiomas) explicando el formato `[texto](url)` del contenido y pidiendo identificar semánticamente links a artículos citados/mencionados, distintos de navegación/redes sociales/CTAs
- [x] 2.4 Tests de `parseMentions` para el nuevo tipo (`article` con/sin `url`, `url` vacía)

## 3. Backend: `enrich-mentions` resuelve menciones de tipo `article` vía Open Graph

- [x] 3.1 Sumar `"article"` a `MENTION_TYPES`/`RawMention` en `enrich-mentions/mention_types.ts`
- [x] 3.2 Validar la URL antes de fetchear: esquema `http`/`https` únicamente, y rechazar hosts que resuelvan a rangos de IP privados/loopback/link-local (mitigación SSRF) — tratar un rechazo como fetch fallido (mención sin enriquecer, con el `link` original igual)
- [x] 3.3 Implementar `resolveArticle(url, fetchImpl)` en `providers.ts`: fetch con timeout corto, extrae `og:title`/`og:image` por regex sobre `<meta property="og:...">`, con fallback a `<title>` si falta `og:title`
- [x] 3.4 Extender `enrichMention` para la rama `article`: `link` SHALL setearse siempre a la URL original (haya o no éxito en el fetch); `name` se reemplaza por el título obtenido solo si el fetch tuvo éxito
- [x] 3.5 Tests de `resolveArticle`/`enrichMention` para `article` (éxito con og:title+og:image, éxito solo con `<title>` como fallback, fetch fallido, URL rechazada por el chequeo SSRF) — todos mockeando `fetchImpl`, sin red real

## 4. App: dominio y modelo

- [x] 4.1 Sumar `MentionType.article` a `core/ai/mention_enricher.dart`; agregar `url` opcional a `RawMention`
- [x] 4.2 Actualizar `RemoteMentionEnricher` y `GeminiArticleSummaryGenerator` para (de)serializar el campo `url`
- [x] 4.3 No hizo falta: `EnrichedMention` no gana un campo `url` separado -- para `article`, `link` ya vale la URL siempre (ver design.md), así que `ArticleSummaryModel` persiste el mismo `link` que ya persistía para los demás tipos, sin cambios

## 5. App: UI

- [x] 5.1 Corregir el gating de tap en `MentionCard`: de `onTap: hasImage ? onTap : null` a `onTap: mention.link != null ? onTap : null` (equivalente para libro/podcast/música, correcto para artículo)
- [x] 5.2 Agregar un ícono placeholder para `MentionType.article` sin imagen (ej. `Icons.link`)
- [x] 5.3 Widget tests: mención de artículo sin imagen pero con link es tappable y dispara `onTap`; mención de artículo con imagen (og:title/og:image) se ve igual que las demás enriquecidas

## 6. Verificación final

- [x] 6.1 `deno test` en `summarize-article/` y `enrich-mentions/` en verde (22/22 cada una)
- [x] 6.2 `flutter analyze` sin warnings
- [x] 6.3 `flutter test` completo en verde (508/509; el único fallo, `app_error_code_localizations_test.dart`, pasa limpio corrido solo — flake de la corrida completa bajo concurrencia, no relacionado a este change, mismo patrón que el flake preexistente de `localized_date_formatter_test.dart`)
- [x] 6.4 Deploy de `summarize-article` y `enrich-mentions` a dev y prod
