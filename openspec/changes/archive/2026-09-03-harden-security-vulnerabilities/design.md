## Context

Cuatro hallazgos independientes de una revisión de seguridad manual, ver proposal.md - Why. Cada uno ya tiene un patrón vecino correcto en el mismo repo (`enrich-mentions/url_safety.ts`, límites por usuario en `check_and_record_ai_usage`, `_YoutubeWebView` que no necesita JS de terceros) que sirve de referencia directa para el fix. No hay dependencias entre los cuatro; se implementan y se despliegan de forma independiente.

## Goals / Non-Goals

**Goals:**
- Cerrar el SSRF de `sync-feeds` sin cambiar el comportamiento observable para una fuente RSS pública legítima.
- Hacer que el rate limit de `create-feed` sea por usuario, sin cambiar el valor del tope (20/hora).
- Eliminar la ejecución de JavaScript sobre HTML de origen no confiable, sin romper el rendering de emails de marketing reales (tablas anidadas, imágenes, YouTube embebido vía `_YoutubeWebView`, que no depende del JS del propio email).
- Reducir la superficie de prompt injection hacia Gemini sin cambiar el contrato de request/response de `summarize-article`/`summarize-articles`, ni la voz editorial ya definida.

**Non-Goals:**
- No se rediseña el modelo de autenticación de ninguna Edge Function.
- No se agrega un sanitizador de HTML tipo allowlist (ej. DOMPurify) — deshabilitar JS alcanza para el riesgo identificado (ejecución de código), no se está resolviendo XSS de robo de estilos/contenido dentro de la propia vista.
- No se cambia el límite diario de resúmenes de IA ni el techo de longitud por artículo (`ai-usage-budget`), solo el aislamiento del contenido dentro del prompt.

## Decisions

### SSRF: duplicar `isSafePublicUrl` en `sync-feeds` en vez de compartir código entre Edge Functions
Cada Edge Function del proyecto se despliega como unidad autocontenida sin imports cruzados entre carpetas de funciones (patrón ya establecido, ver comentario en `enrich-mentions/entitlement.ts`). Se copia `url_safety.ts` (y su test) a `supabase/functions/sync-feeds/`, igual criterio que ya se usa para `entitlement.ts` duplicado entre `summarize-article` y `summarize-articles`. Alternativa descartada: extraer un paquete compartido importado por URL — rompería el patrón de despliegue independiente ya elegido deliberadamente en este proyecto.

La validación se aplica en `fetchWithTimeout` (o inmediatamente antes de llamarla dentro de `syncSource`), antes de la primera request de red hacia `feed_url`.

### Rate limit de `create-feed`: agregar `.eq("user_id", userId)` al conteo
`generated_feeds` no tiene hoy columna `user_id` (los feeds generados no están asociados a ningún usuario en el modelo de datos — ver `20260714154141_email_to_rss_feeds.sql`). Antes de poder contar por usuario hace falta:
1. Agregar `user_id uuid not null references auth.users(id) on delete cascade` a `generated_feeds`, seteado desde `create-feed` con el `userData.user.id` ya resuelto.
2. Filtrar el conteo de `MAX_FEEDS_PER_HOUR` por ese `user_id`.

Alternativa descartada: mantener el límite global pero subir el número — no resuelve el problema de fondo (un usuario sigue pudiendo agotar la cuota de otro).

### JavaScript no confiable neutralizado por remoción de texto dirigida, no por sandboxing de iframe ni por deshabilitar JS del WebView
**Dos pivotes respecto del plan original de esta sección**, ambos surgidos de verificación manual del usuario en simulador de iPad (no reproducibles sin dispositivo real):

1. **Intento 1** (`JavaScriptMode.unrestricted` → `JavaScriptMode.disabled` en todo `_RawEmailWebView`): cortaba el contenido en portrait y no scrolleaba en landscape. Causa: `JavaScriptMode.disabled` es todo-o-nada a nivel de `WebViewController` — también apagaba el propio script inyectado por la app para medir `scrollHeight` (`ReevoContentHeight`/`ResizeObserver`), no solo el del email. La altura fija puesta en su lugar no podía acomodar newsletters de longitud variable.
2. **Intento 2** (aislar el HTML no confiable dentro de un `<iframe sandbox="allow-same-origin" srcdoc="...">`, manteniendo `JavaScriptMode.unrestricted` en el documento contenedor para seguir midiendo la altura desde afuera): en teoría más robusto (el `sandbox` es una restricción del motor del navegador, no un filtro de texto), pero mostró contenido en blanco para newsletters reales compuestos mayormente de bloques con imagen (TechCrunch/Sailthru) — indicio de que WKWebView no resuelve de forma confiable URLs de imagen relativas dentro de un `srcdoc` contra el `baseUrl` del documento contenedor (comportamiento documentado como inconsistente en WebKit). No hay forma de diagnosticar esto más a fondo sin acceso al dispositivo, así que se descartó en vez de seguir iterando a ciegas.

La solución final vuelve a cargar el HTML no confiable directo en el documento del `WebView` (idéntico al comportamiento original, JS habilitado, medición de altura por `ResizeObserver` sobre `document.body`, sin indirección de iframe), pero antes le aplica `stripScriptExecutionVectors`: una remoción de texto dirigida a los vectores de ejecución conocidos —

- Bloques `<script>...</script>` (incluido uno sin `</script>` de cierre, tratado igual que lo haría un parser HTML real: se descarta todo lo que sigue).
- Atributos `on*=` (`onclick`, `onload`, `onerror`, etc.), con o sin comillas.
- El esquema `javascript:`/`vbscript:` en atributos que aceptan una URI (`href`, `src`, `action`, `formaction`).

Esto es deliberadamente más débil que un sandbox reforzado por el navegador (ver Non-Goals: no es un sanitizador HTML tipo allowlist, y en teoría es evadible con un payload lo bastante creativo que ninguna de estas expresiones regulares reconozca), pero es el único de los tres enfoques que preserva el rendering ya comprobado (mismo código de carga que el original, sin reparseo/reserialización del árbol que reintroduzca riesgo de mutation-XSS), y cierra el vector más realista para este caso (un remitente de email agregando un `<script>` o `on*=` esperando que se ejecute en un WebView sin restricciones, que es exactamente lo que hacía antes de este change).

El WebView de "ver artículo original" (`webview_flutter_article_web_view.dart`) y `_YoutubeWebView` no se tocan: el primero navega a una URL pública elegida deliberadamente por el usuario (mismo modelo de confianza que un navegador normal), y el segundo carga un `<iframe>` fijo controlado por la app, no HTML del remitente.

### Prompt injection: delimitador explícito envolviendo el contenido del artículo
Se envuelve el título+contenido de cada artículo con un delimitador de bloque (ej. `<article_content>...</article_content>` o una marca de cierre igual de explícita) y una frase final en las instrucciones de sistema que indica que todo lo que está dentro del delimitador es contenido a resumir, nunca una instrucción — mismo patrón recomendado por Google para mitigar prompt injection contra Gemini. Se aplica igual en los 3 idiomas de `INSTRUCTIONS` (`summarize-article`) y en el prompt equivalente de `summarize-articles`. No se agrega detección/bloqueo de intentos de injection (fuera de alcance): el objetivo es que la instrucción original del sistema no sea reemplazable por contenido externo, no detectar el intento.

## Risks / Trade-offs

- [Validar `feed_url` en `sync-feeds` podría rechazar una fuente RSS legítima detrás de un balanceador con IP momentáneamente clasificada como privada, o un feed self-hosted en la propia LAN del usuario] → Mitigación: mismo criterio ya validado y testeado en `enrich-mentions` para tráfico de producción; una fuente self-hosted en LAN nunca fue alcanzable igual desde una Edge Function en la nube, así que no hay regresión real de funcionalidad.
- [Agregar `user_id` a `generated_feeds` requiere backfill para filas existentes sin usuario asociado] → Mitigación: dado que hoy la tabla no registra el usuario creador, las filas existentes no tienen forma de atribuirse retroactivamente; se agrega la columna con backfill a un usuario "desconocido" no es viable — se deja `user_id` nullable para filas históricas y el conteo del rate limit trata `NULL` como "no cuenta para el límite de nadie" (no afecta feeds nuevos, que siempre llevan `user_id`).
- [Deshabilitar JS a nivel de todo `_RawEmailWebView` rompía la medición dinámica de altura, no solo el JS del email] → Materializado en la verificación manual del usuario (contenido cortado en portrait, sin scroll en landscape); descartado, ver "Dos pivotes" arriba.
- [Aislar el contenido en un iframe `sandbox`/`srcdoc` rompía la carga de imágenes de newsletters reales, dejándolos en blanco] → Materializado en una segunda verificación manual del usuario (TechCrunch); descartado en favor de `stripScriptExecutionVectors` sobre el documento único, que reutiliza el mismo pipeline de carga ya comprobado.
- [`stripScriptExecutionVectors` es una remoción de texto, no una garantía a nivel de motor de navegador -- un payload lo bastante creativo (ej. explotando una particularidad de parseo específica de WebKit no cubierta por las expresiones regulares) podría evadirla] → Aceptado como reducción de superficie, no eliminación total (mismo criterio que el delimitador de prompt injection): bloquea el vector más realista (`<script>`/`on*=`/`javascript:` directos) sin reintroducir el riesgo de rendering roto de los dos intentos anteriores.
- [El delimitador de contenido no es una garantía criptográfica contra prompt injection, un modelo de lenguaje puede seguir siendo influenciado por contenido dentro del delimitador] → Mitigación: se acepta como reducción de superficie, no eliminación total (ver Non-Goals); el impacto de un resumen "contaminado" queda acotado a lo que ese usuario ve de su propio artículo, sin acceso a datos de otros usuarios ni a las credenciales del backend.

## Migration Plan

Cuatro cambios independientes, cada uno desplegable por separado:
1. `sync-feeds`: agregar `url_safety.ts` + validación, desplegar función a `reevo-dev` y `reevo` (confirmar con el usuario ambos proyectos, ver CLAUDE.md).
2. `create-feed`: migración SQL (`user_id` en `generated_feeds`) + cambio de función, en ese orden — la migración debe aplicarse antes de desplegar el código que la usa.
3. `fwh_html_content_renderer.dart`: cambio de cliente puro, va en el próximo build de la app.
4. `summarize-article` / `summarize-articles`: cambio de prompt, desplegado a ambos proyectos de Supabase igual que (1).

Sin rollback especial: cada cambio es reversible revirtiendo el commit/deploy correspondiente, sin dependencias entre sí.
