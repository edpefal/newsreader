## 1. SSRF en `sync-feeds`

- [x] 1.1 Copiar `enrich-mentions/url_safety.ts` (y su test) a `supabase/functions/sync-feeds/url_safety.ts`
- [x] 1.2 Llamar `isSafePublicUrl(source.feed_url)` en `syncSource` antes de `fetchWithTimeout`; si es `false`, tratar la fuente como fallida (mismo camino que el `catch` existente: `has_error = true`, sin interrumpir las demás fuentes)
- [x] 1.3 Agregar tests para `syncSource`/`Deno.serve` cubriendo una fuente con `feed_url` privado/localhost y una con esquema no http(s) (cubierto por `url_safety_test.ts`, siguiendo el patrón del resto de la carpeta de solo testear las funciones puras extraídas, no `index.ts`/`Deno.serve` directamente)
- [x] 1.4 Correr `deno test` en `supabase/functions/sync-feeds/`
- [x] 1.5 Desplegado a `reevo` (prod, `avyaxzhdilhufyimrzzb`) y `reevo-dev` (`xgwnxhpdcrghrtdbrmpn`) por instrucción explícita del usuario

## 2. Rate limit por usuario en `create-feed`

- [x] 2.1 Crear migración SQL: agregar `user_id uuid references auth.users(id) on delete cascade` (nullable) a `generated_feeds`
- [x] 2.2 En `create-feed/index.ts`, guardar `user_id: userData.user.id` en el `insert` de `generated_feeds`
- [x] 2.3 Filtrar el conteo de `MAX_FEEDS_PER_HOUR` con `.eq("user_id", userData.user.id)`
- [x] 2.4 Actualizar/agregar tests de `create-feed` (no había tests previos ni lógica pura extraída en esta función -- mismo patrón que el resto de la carpeta de no testear `index.ts`/`Deno.serve` directamente; se verificó con `deno check`)
- [x] 2.5 Correr `deno test` en `supabase/functions/create-feed/` (sin tests que correr; `deno check` pasa)
- [x] 2.6 Migración aplicada y `create-feed` desplegado a `reevo` (vía `supabase db push` + `functions deploy`) y `reevo-dev` (el historial de migraciones de `reevo-dev` está desincronizado del CLI -- ver nota en design.md/decisiones de esta sesión -- así que la migración se aplicó ahí con `mcp__supabase__apply_migration` tras confirmar por `list_tables` que `generated_feeds` no tenía `user_id` todavía)

## 3. JavaScript deshabilitado en HTML de email no confiable

- [x] 3.1 En `fwh_html_content_renderer.dart`, aplicar `stripScriptExecutionVectors` (quita `<script>`, atributos `on*=`, y esquemas `javascript:`/`vbscript:`) al HTML no confiable antes de cargarlo en `_RawEmailWebView`, sobre el documento único de siempre -- tras dos pivotes fallidos, ver nota más abajo
- [x] 3.2 El mecanismo de medición de altura vuelve a ser el original sin cambios: `JavaScriptMode.unrestricted` en todo el `WebViewController`, `ResizeObserver`/`ReevoContentHeight` sobre `document.body` -- ya no hace falta "ajustarlo", se restauró tal cual estaba antes de esta sesión
- [x] 3.3 Confirmado por el usuario en simulador de iPad, en tres rondas: la 1ª versión (`JavaScriptMode.disabled` + altura fija) cortaba contenido y no scrolleaba en landscape; la 2ª versión (iframe `sandbox`/`srcdoc`) dejaba newsletters reales (TechCrunch) en blanco por un problema de resolución de URLs relativas de WKWebView; la 3ª versión (`stripScriptExecutionVectors` sobre documento único) confirmada como correcta por el usuario
- [x] 3.4 Correr `flutter analyze` y `flutter test` (acotado a los archivos/tests tocados; la corrida completa queda en la tarea 5.1) -- se agregaron tests unitarios para `stripScriptExecutionVectors` en `test/unit/core/widgets/fwh_html_content_renderer_test.dart` (cubren `<script>` con/sin cerrar, con atributos, multilínea, mayúsculas/minúsculas, atributos `on*=` con los 3 estilos de comillas, esquemas `javascript:`/`vbscript:`, y que HTML/CSS normal de un newsletter no se toque)

**Nota de diseño (dos pivotes sobre el plan original, ambos por regresiones de rendering encontradas en simulador real, no reproducibles sin dispositivo):**
1. Deshabilitar JS a nivel de todo el `WebViewController` (plan original de design.md) apagaba también el script propio de la app que medía `scrollHeight` -- `JavaScriptMode.disabled` es todo-o-nada. La altura fija puesta en su lugar cortaba newsletters largos.
2. Aislar el HTML no confiable en un `<iframe sandbox="allow-same-origin" srcdoc="...">` (más robusto en teoría, bloqueo a nivel de motor de navegador) dejaba newsletters reales compuestos mayormente de imágenes en blanco -- indicio de que WKWebView no resuelve de forma confiable URLs relativas dentro de un `srcdoc` contra el `baseUrl` del documento contenedor.

La solución final vuelve al documento único de siempre (mismo pipeline de carga ya comprobado, sin indirección de iframe) y en su lugar remueve del texto los vectores de ejecución conocidos antes de cargarlo (`stripScriptExecutionVectors`). Es más débil en teoría que un sandbox reforzado por el navegador (evadible con un payload lo bastante creativo), pero es el único de los tres enfoques que no rompió el rendering real, y cierra el vector más realista (`<script>`/`on*=`/`javascript:` directos en un email).

## 4. Delimitador de contenido en prompts de Gemini

- [x] 4.1 En `summarize-article/index.ts`, envolver el contenido del artículo con un delimitador explícito (`<article_content>...</article_content>`) y agregar una frase en `INSTRUCTIONS` (los 3 idiomas) indicando que ese contenido nunca se trata como instrucción
- [x] 4.2 Aplicar el mismo delimitador (`<articles_content>...</articles_content>`) en el prompt de `summarize-articles/index.ts`
- [x] 4.3 Actualizar tests existentes que arman/verifican el prompt en ambas funciones (ningún test existente hace assertions sobre el prompt exacto -- nada que actualizar)
- [x] 4.4 Correr `deno test` en `supabase/functions/summarize-article/` y `supabase/functions/summarize-articles/` (22 y 13 tests respectivamente, todos pasan; `deno check` también pasa en ambos `index.ts`)
- [x] 4.5 Desplegadas a `reevo` y `reevo-dev` por instrucción explícita del usuario

## 5. Cierre

- [x] 5.1 Correr `flutter analyze` y `flutter test` completos (0 issues, 542/542 tests pasan tras el ajuste final de la tarea 3)
- [x] 5.2 Verificar que no queden warnings de `openspec validate --strict` para este change
