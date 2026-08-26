## Context

### Investigación previa (sesión anterior, sin fix)

Se extrajo el `contentHtml` real del artículo reportado ("Going after ghosts", The Morning Brew, recibido vía un servicio de email-a-RSS como killthenewspaper) directamente del Hive box de un simulador (`articles_dev.hive`). El HTML real (~94 KB) es un email de marketing típico, con 74 aperturas de `<table>` y hasta **9 niveles de anidamiento**, usando el atributo `valign="middle"` (nunca `baseline`, ni en atributo ni en CSS).

Con ese HTML como fixture (`test/fixtures/newsletter_nested_tables.html`) se descartaron dos hipótesis por evidencia directa: que el renderizado no produjera contenido visible, y que no hubiera indicador de carga mientras tanto. Un benchmark confirmó que la profundidad de anidamiento hace el renderizado ~5.5x más lento (2267ms vs. 410ms con tablas aplanadas a `<div>`). Durante ese mismo test aparecieron excepciones de la capa de rendering de Flutter (`computeDryBaseline`, `RenderBox was not laid out`) en frames posteriores al render correcto, sin confirmar si eran inofensivas o la causa real del reporte.

### Confirmación de causa raíz (esta sesión)

Se revisó Sentry (org `reevo`, proyecto `reevo-dev`) y se encontraron **30 issues activos y escalando**, con miles de eventos acumulados, el más reciente a minutos de esta investigación (`last seen: 2026-08-24T15:08:33Z`), todos con la misma firma:

```
AssertionError: 'package:flutter/src/rendering/box.dart': Failed assertion:
line 2251 pos 12: 'hasSize': RenderBox was not laid out: <RenderObject># relayoutBoundary=upN NEEDS-PAINT
```

Nivel `fatal`, `handled: no`, ocurriendo durante `performLayout()` en un simulador iOS real (`iPhone18,3`, iOS 26.2, Flutter 3.44.6 stable, `compile_mode: debug`, release `com.artlab.reevo@1.8.0+9`). No hay issues equivalentes en `reevo-prod` (release sin asserts activos — ver "Por qué no aparece en prod" más abajo).

El stack trace de dos eventos representativos (`REEVO-DEV-B`, `REEVO-DEV-8`) ubica el origen en `flutter_widget_from_html_core`:

```
_TableRenderObject.performLayout (html_table.dart:877)
  ← _TableRenderLayouter.compute (html_table.dart:321)
  ← _TableRenderLayouter.step3MinIntrinsicWidth (html_table.dart:426)
  ← RenderPositionedBox.performLayout (shifted_box.dart:484)
  ← ... (varias capas de _RenderCssSizing / _HorizontalMarginRenderObject)
```

y el `debugCreator` de `REEVO-DEV-8` confirma la cadena de widgets involucrada:

```
Column ← Padding ← WidgetPlaceholder ← HtmlTableCell ← HtmlTable
  ← _ValignBaselineClearer ← _ValignBaselineInheritedWidget
  ← ValignBaselineContainer ← LayoutBuilder ← _MinWidthZero ← CssBlock ← ...
```

Se confirmó en el código fuente de `flutter_widget_from_html_core` 0.15.2 (`lib/src/internal/ops/tag_table.dart:94`, función `_onTableRenderBlock`) que **todo `<table>` se envuelve incondicionalmente en `ValignBaselineContainer`**, sin importar si algún `<td>` tiene `vertical-align: baseline` explícito — el wrapper existe para soportar ese caso, pero se aplica siempre. Esto explica por qué el fixture de Morning Brew (solo `valign="middle"`, nunca `baseline`) también dispara el mismo mecanismo: el bug no depende de usar `vertical-align: baseline`, depende de la profundidad/complejidad del anidamiento de tablas en sí.

El mecanismo exacto: el algoritmo de ancho intrínseco mínimo de la tabla (`_TableRenderLayouter.step3MinIntrinsicWidth`) hace layouts de prueba de celdas para medir anchos, y con tablas anidadas profundas termina consultando el tamaño (`RenderBox.size`) de un RenderObject hijo (`_ValignBaselineClearerRenderObject`, `RenderPositionedBox`, u otros según el frame) que Flutter todavía no terminó de layoutear en esa pasada — dispara la aserción `hasSize`. Como el RenderObject que falla puede estar en cualquier nivel del árbol (los 30 issues muestran una decena de tipos de RenderObject distintos como culpable, incluyendo capas ajenas a `fwfh_core` como `RenderPointerListener`, `RenderFlex`, `_RenderScrollSemantics`), **la excepción se propaga hacia arriba por todo el pipeline de layout de ese frame** — en el evento `REEVO-DEV-B` la traza llega hasta `_ScaffoldLayout.performLayout`, es decir, corrompe el layout de la pantalla completa (AppBar incluido), no solo el área de contenido del artículo. Esto coincide exactamente con el reporte original: "lector completamente vacío... como si el artículo no tuviera contenido", sin spinner visible.

**Por qué no aparece en `reevo-prod`:** los eventos capturados tienen `dart_context.compile_mode: debug` y `environment: development`. La aserción (`assert(hasSize, ...)` dentro de `RenderBox.size`, en Flutter) se compila condicionalmente y no se ejecuta en builds release/profile sin `--enable-asserts`. En producción el mismo estado inconsistente probablemente no lanza una excepción capturable por Sentry — el árbol de render simplemente queda con RenderObjects sin layoutear/pintar correctamente, lo que se manifiesta como el área en blanco reportada por el usuario, sin ningún crash reportado. Esto es consistente con que el reporte original viniera de un usuario real (probablemente en un build release/TestFlight) sin que hubiera un evento de error correspondiente.

**No se encontró un fix upstream confirmado:** se buscaron issues en `daohoangson/flutter_widget_from_html` (los más cercanos, #256 y #742, son de 2020-2022 contra versiones `0.4`/`0.5`, no aplicables) y se revisó el changelog de `flutter_widget_from_html_core` entre `0.15.2` (versión actual del proyecto) y `0.17.2` (última en pub.dev) — no hay una entrada que mencione baseline, dry-layout, RenderBox o tablas anidadas. Actualizar el paquete a ciegas no es una corrección confiable sin poder validarla contra Flutter 3.44.6 y este fixture real.

## Goals / Non-Goals

**Goals:**
- Eliminar el crash/corrupción de layout confirmado en Sentry para artículos con tablas anidadas, sin depender de un fix upstream no confirmado.
- Mantener el contenido del newsletter legible (texto, imágenes, links) aunque se pierda la maquetación visual exacta en columnas que las tablas de layout producían.
- Dejar un test de regresión que reproduzca el crash original contra el fixture real y confirme que el fix lo evita.

**Non-Goals:**
- No se intenta preservar la disposición visual exacta en columnas/celdas de las tablas de layout del newsletter — son tablas usadas por herramientas de email marketing puramente para maquetación, no datos tabulares; renderizarlas como bloques verticales apilados es una pérdida de fidelidad visual aceptable a cambio de que el artículo se pueda leer.
- No se actualiza `flutter_widget_from_html` a una versión más nueva en este change — queda como alternativa futura si se confirma que corrige el bug, pero no es parte de este fix.
- No se modifica el criterio de truncamiento existente (`FeedContentChecker`) ni el manejo de imágenes/YouTube ya presente en `fwh_html_content_renderer.dart`.

## Decisions

**Aplanar TODAS las tablas a `<div>`, no solo las anidadas.** La causa raíz no depende de la profundidad de anidamiento en sí sino de que cualquier `<table>` se envuelve en `ValignBaselineContainer`/pasa por `_TableRenderLayouter`. Dejar intacta la tabla de nivel superior (y aplanar solo las internas) seguiría invocando el mismo algoritmo de layout para esa tabla externa. Aplanar todo el árbol `table/thead/tbody/tfoot/tr/th/td/caption` a `<div>` evita el algoritmo de `fwfh_core` por completo para este tipo de contenido.

**Transformación quirúrgica por regex sobre el string crudo, sin parsear/re-serializar el HTML.** Mismo enfoque y misma razón que `stripInlineTextColors` en el mismo archivo: reemplazar solo el nombre de la etiqueta de apertura/cierre (`<table ...>` → `<div ...>`, `</table>` → `</div>`, y análogo para `thead`/`tbody`/`tfoot`/`tr`/`th`/`td`/`caption`), preservando el resto de atributos intactos. Un roundtrip de parseo puede reestructurar el árbol de un documento HTML mal formado (común en newsletters) — eso ya rompió el layout de embeds de YouTube en una versión anterior de este archivo. Atributos específicos de tabla que quedan en un `<div>` (`valign`, `border`, `cellpadding`, `colspan`, `rowspan`, `width` numérico sin unidad) son simplemente ignorados por el motor de CSS de `fwfh_core` al no aplicar a un `div` — no rompen el render.

**Se elimina el `<colspan>`/`<rowspan>` semántico sin reemplazo.** Al pasar a `<div>`, cada celda pasa a ser un bloque independiente; no se intenta reconstruir la agrupación visual que un `colspan`/`rowspan` producía. Aceptable dado el Non-Goal de preservar maquetación exacta.

## Risks / Trade-offs

- [Newsletters que sí usan tablas para datos tabulares reales (ej. una tabla de precios o resultados) pierden su layout en columnas y se leen como una lista vertical] → Aceptable: el contenido sigue siendo legible (todas las celdas se muestran, en orden), y el caso reportado (y el fixture real disponible) es maquetación de marketing, no datos tabulares. No se tiene evidencia de fuentes suscritas que dependan de tablas de datos reales.
- [El regex de renombrado de tags podría no cubrir casos de HTML genuinamente inválido, ej. tags sin cerrar o mal anidados] → Mismo riesgo que ya asume `stripInlineTextColors` para este archivo; el parser HTML tolerante que usa `fwfh_core` internamente ya maneja HTML mal formado razonablemente bien una vez que las etiquetas de tabla dejan de estar presentes.
- [No se valida en un dispositivo real durante este change, solo en el entorno de test] → El test de regresión usa el fixture real capturado del dispositivo y reproduce el mismo tipo de excepción documentada en Sentry; se considera evidencia suficientemente directa dado que la causa raíz ya se confirmó con eventos de producción/desarrollo reales.

## Verificación post-implementación (primer intento) y fix revertido

Con el fix aplicado (`flattenTables` + `stripInlineTextColors`) y un hot restart real en simulador iOS, se confirmó visualmente que el contenido de newsletters con tablas anidadas (Daily Stoic, The Morning Brew) ya renderizaba -- antes no se veía nada. En Sentry, los issues de `RenderBox was not laid out` quedaron congelados sin eventos nuevos durante la prueba, confirmando que el crash dejó de ocurrir. También se agregó `stripInlineBackgroundColors` para el fondo blanco inline que quedó visible una vez desbloqueado el render (ver tarea 5 en `tasks.md`).

**Sin embargo, al probar un newsletter real distinto** (The Morning Brew, "Oh, Canada", 24 de agosto -- un HTML distinto al fixture usado para desarrollar el fix, "Going after ghosts", 22 de agosto) **apareció una regresión más grave que el bug original**: texto e imágenes completamente superpuestos e ilegibles. El screenshot mostró bloques de texto encimados sobre imágenes, títulos mezclados con el cuerpo de otras secciones, sin ningún orden reconocible.

**Causa de la regresión:** las tablas de layout de email no solo sirven para dar estructura secuencial (que es lo único que `flattenTables` preserva al convertir cada celda en un `<div>` independiente) -- también proveen la contención de ancho/alto que evita que el contenido de una celda se superponga con el de otra. `RenderMode.column` de `flutter_widget_from_html` apila bloques verticalmente pero no tiene el mecanismo de negociación de columnas de una tabla real; sin esa contención, layouts de columnas lado a lado (comunes para poner texto sobre/junto a imágenes, o para agrupar CTAs) colapsan unos sobre otros. Se verificó que el fixture nuevo no usa `rowspan`/`colspan`/`position: absolute` -- el problema no es un caso raro, es que **aplanar toda tabla a `<div>`, sin excepción, es fundamentalmente incompatible con cómo los newsletters de marketing usan tablas para maquetación real (no solo para evitar el bug de baseline)**.

**Se revirtió el fix completo** (`flattenTables`, `stripInlineBackgroundColors`, y su aplicación en `FwhHtmlContentRenderer.build`) de vuelta al estado anterior a esta sesión (solo `stripInlineTextColors`). El test de regresión del fixture (`fwh_html_content_renderer_newsletter_test.dart`) se mantiene, actualizado para no depender de las funciones revertidas -- sigue documentando que el contenido del fixture original sí renderiza en el entorno de test (el crash de Sentry nunca se reprodujo ahí en ninguna sesión), como línea base para cualquier intento futuro.

## Segundo intento: actualizar `flutter_widget_from_html` a 0.17.2 (también revertido)

Se comparó el código fuente de `_TableRenderLayouter.step3MinIntrinsicWidth` entre `0.15.2` y `0.17.2`: la línea que hacía `layouter(child, const BoxConstraints())` (layout **sin restricciones**, la sospecha original de causa raíz) fue reemplazada en `0.17.2` por `layouter(child, constraints)` (con las constraints reales del padre). Se actualizó `pubspec.yaml` a `flutter_widget_from_html: ^0.17.0` (resolvió a `0.17.2`) sin tocar `fwh_html_content_renderer.dart` (que había vuelto a su estado original, solo `stripInlineTextColors`).

**El crash persiste, y de forma más grave.** Probado en simulador real contra el mismo artículo "Oh, Canada": pantalla en blanco, sin spinner -- exactamente el síntoma original. La Debug Console mostró un **loop continuo de excepciones** (decenas de `AssertionError: 'hasSize'` distintas por segundo, con Sentry reportando "Task dropped due to reaching max parallel tasks"), nunca llega a estabilizarse en un frame limpio. Los stack traces siguen apuntando a `_TableRenderLayouter.step3MinIntrinsicWidth` y `_ValignBaselineClearerRenderObject`, junto con decenas de otros tipos de RenderObject completamente ajenos a `fwfh_core` (`RenderPointerListener`, `RenderSemanticsGestureHandler`, incluso el `Column` de `reader_screen.dart:200`) fallando `hasSize` en frames sucesivos con distintos `relayoutBoundary`.

Esto indica que la hipótesis del "layout sin restricciones" en esa línea específica era real pero **incompleta**: el fix de esa línea en 0.17.2 no resuelve el problema de fondo, que parece ser una corrupción sistémica del scheduling de relayout que se propaga por todo el árbol de widgets de la pantalla (no solo el contenido HTML), de forma persistente entre frames -- más grave que el síntoma original de "un solo crash silencioso".

**Se revirtió `pubspec.yaml` a `flutter_widget_from_html: ^0.15.0`** (vuelve a resolver `0.15.3`). 436/436 tests, `flutter analyze` limpio, sin diff neto contra el estado previo a esta sesión.

## Estado final de la sesión

**El crash reportado en Sentry sigue sin resolverse.** Dos intentos de fix, ambos revertidos:
1. Aplanar todas las tablas a `<div>` -- elimina el crash pero rompe layouts de columnas reales (superposición de texto/imágenes) en newsletters con maquetación más compleja que el fixture de desarrollo.
2. Actualizar `flutter_widget_from_html` a `0.17.2` -- no elimina el crash; el mismo mecanismo persiste de forma más severa (loop continuo en vez de un crash puntual).

Alternativas no probadas al cierre de esa sesión:
- Limitar el aplanado a tablas más allá de cierta profundidad de anidamiento (en vez de aplanar todo el árbol), preservando el nivel superior donde probablemente vive la maquetación de columnas real -- no se investigó si el crash requiere una profundidad mínima o si un solo nivel de tabla ya lo dispara.
- Parchear o hacer fork puntual de `flutter_widget_from_html_core` (`_TableRenderLayouter`, `ValignBaselineContainer`) en vez de depender de la versión publicada -- dado que ni `0.15.2` ni `0.17.2` resuelven esto, un fork dirigido puede ser la única vía dentro de esta librería.
- Evaluar una librería de renderizado de HTML distinta para newsletters con tablas complejas (cambio de mayor alcance, no explorado).
- Reproducir el loop de excepciones con más detalle (capturar la secuencia completa de relayout boundaries afectados) para entender si el disparador real es distinto al que se investigó -- las dos hipótesis probadas hasta ahora (BoxConstraints() sin restricciones, versión de paquete) no explican por qué el problema empeoró con el upgrade.

## Tercer intento (propuesto): detectar email crudo y renderizarlo en WebView

### Por qué el HTML tiene esta forma

Se investigó una librería alternativa (`flutter_html` + `flutter_html_table`) como posible reemplazo de `flutter_widget_from_html`. Se descartó: es una librería nativa (HTML → widgets de Flutter) igual que `fwfh_core`, y su propia documentación dice explícitamente que **no soporta tablas anidadas** -- cambiaría un bug conocido por una limitación conocida, sin resolver el problema. Está además menos activamente mantenida (última versión hace 17 meses, contra 4 meses de `flutter_widget_from_html`). Ninguna librería de renderizado *nativo* del ecosistema Flutter declara soporte real para tablas anidadas arbitrarias -- tiene sentido: reimplementar el algoritmo de layout de tablas de un motor de browser es exactamente donde `fwfh_core` se rompe.

En cambio, se encontró evidencia concreta de **por qué el HTML tiene esta forma en primer lugar**: el fixture real (`test/fixtures/newsletter_nested_tables.html`) contiene `xmlns:v="urn:schemas-microsoft-com:vml"` y `xmlns:o="urn:schemas-microsoft-com:office:office"` (namespaces VML que solo existen para sobrevivir al motor de renderizado de Word que usa Outlook de escritorio), `<meta name="x-apple-disable-message-reformatting">` (hack de Apple Mail) y `<meta http-equiv="X-UA-Compatible" content="IE=edge">` (hack de compatibilidad de IE/Outlook). Estas marcas son exclusivas de **email de marketing crudo** construido para sobrevivir en clientes de correo de escritorio -- nunca aparecen en HTML generado para la web.

Esto explica el patrón reportado: servicios de email-a-RSS como `kill-the-newsletter.com` reenvían el email crudo tal cual como contenido del feed, sin limpiarlo. Un feed RSS nativo de un blog/publicación usa HTML semántico normal, sin las tablas anidadas a 9 niveles que ese hack de compatibilidad con Outlook produce. El problema no es "tablas anidadas" en abstracto -- es específicamente contenido de email crudo, una fuente identificable y acotada.

### Decisión: detectar el patrón en vez de transformar todo el HTML

En vez de una transformación que aplica a **todo** el contenido HTML (lo que rompió layouts reales en el intento 1), se detecta el patrón de email crudo por sus marcas características y se cambia de estrategia de render **solo** para ese subconjunto. El resto del contenido (la inmensa mayoría de las fuentes) sigue exactamente igual que hoy.

```dart
bool looksLikeRawEmailHtml(String htmlContent) =>
    htmlContent.contains('xmlns:v="urn:schemas-microsoft-com:vml"') ||
    htmlContent.contains('xmlns:o="urn:schemas-microsoft-com:office:office"');
```

Se eligen estas dos marcas (no `x-apple-disable-message-reformatting` ni `IE=edge`, que son más genéricas y podrían aparecer en HTML no problemático) porque son las más específicas: ningún generador de HTML para web las produce, y ambas ya están confirmadas presentes en el fixture real. Falso negativo (no detectar un email crudo real) dejaría ese artículo en el camino actual -- ni mejor ni peor que hoy. Falso positivo (enrutar contenido normal a WebView sin necesidad) es el riesgo a minimizar eligiendo marcas inequívocas.

### Decisión: renderizar el subconjunto detectado en un WebView, no en HtmlWidget

Un motor de browser real (WKWebView/Chromium, vía `webview_flutter`, ya dependencia del proyecto) resuelve tablas anidadas arbitrarias correctamente porque es exactamente su trabajo -- no hay un `_TableRenderLayouter` casero que romper. El proyecto ya tiene precedente de este patrón: `_YoutubeWebView` en este mismo archivo ya usa `WebViewController()..loadHtmlString(...)` para embeds. El widget nuevo sigue el mismo patrón, cargando el `contentHtml` completo en vez de un fragmento de iframe.

**No se aplica `stripInlineTextColors`/`stripInlineBackgroundColors` al contenido detectado como email crudo.** Ese HTML fue diseñado con su propia paleta de marca para verse bien en un cliente de correo con fondo claro -- es exactamente el tipo de contenido para el que forzar los colores del theme produciría peor resultado, no mejor (un email armado con cuidado alrededor de un fondo blanco, con imágenes que asumen ese fondo, se ve peor forzado a dark mode que mostrado con su diseño original). Se acepta que estos artículos se lean con fondo claro, igual que se verían en Gmail o Apple Mail.

### Decisión: WebView de altura dinámica dentro del `SingleChildScrollView` existente

`ReaderScreen` ya envuelve todo el contenido (título, metadata, divider, `FwhHtmlContentRenderer`) en un único `SingleChildScrollView`. Un `WebViewWidget` necesita una altura acotada (no puede crecer con su contenido como un widget nativo), así que insertarlo directamente ahí requeriría o (a) darle una altura fija arbitraria con scroll propio -- rompe la experiencia de scroll único de la pantalla -- o (b) medir la altura real del contenido cargado y fijarla dinámicamente.

Se elige (b): usar un `JavaScriptChannel` para que la página reporte su altura real (`document.documentElement.scrollHeight`) después de `onPageFinished` y de que las imágenes carguen (via `ResizeObserver` inyectado, no un solo call estático, para capturar reflows tardíos por imágenes), y usar esa altura para dimensionar un `SizedBox` alrededor del `WebViewWidget` con `setState`. Mientras la altura es desconocida, se muestra un placeholder de altura mínima con el mismo `CircularProgressIndicator` que ya usa el HTML nativo, para consistencia visual. Esto mantiene `ReaderScreen` sin ningún cambio -- toda la lógica queda contenida en `FwhHtmlContentRenderer`/el widget interno nuevo, igual que el resto de esta clase.

No se cambia el resto de la UI de `ReaderScreen` (título, metadata, favorito, divider, hint de contenido truncado) -- solo el contenido central cambia de estrategia de render para el subconjunto detectado.

## Riesgos de este tercer intento

- [Falso positivo de detección: contenido normal enrutado a WebView innecesariamente] → Mitigado eligiendo marcas VML/Office que son extremadamente específicas de email de marketing crudo; se agregan tests unitarios con HTML de blog/web típico confirmando que NO activan la detección.
- [El content del email crudo puede tener sus propios problemas al cargar en WebView -- por ejemplo `<script>` de tracking de email marketing, o recursos externos que no cargan] → `WebViewController` ya usa `JavaScriptMode.unrestricted` en `_YoutubeWebView`; se evalúa si conviene restringir JS solo a lo necesario para el `ResizeObserver` en este caso, dado que el contenido es de un remitente no confiable (más superficie que un iframe de YouTube). A definir en tasks.
- [Medir altura vía JS agrega latencia perceptible antes de mostrar contenido] → Aceptable: el HTML nativo con `HtmlWidget` ya tardaba ~2.3s en el benchmark del intento 1 para este mismo fixture; el placeholder con spinner ya es el comportamiento esperado hoy.
- [No se valida en un dispositivo real dentro de esta sesión, solo se documenta el diseño] → Queda como tarea de `/opsx:apply` y verificación manual, igual que los intentos anteriores.

## Open Questions

- ¿El `ResizeObserver` inyectado captura de forma confiable todos los reflows relevantes (imágenes lentas, fonts) sin dejar contenido cortado o espacio en blanco de más? Requiere probarse contra el fixture real y, si es posible, contra "Oh, Canada".
- ¿Hace falta restringir `JavaScriptMode` para contenido de remitente no confiable, o el sandboxing por defecto de `webview_flutter` (sin acceso a APIs nativas, sin cookies compartidas con el resto de la app) ya es suficiente?

## Open Questions

- ¿Por qué el upgrade a 0.17.2 -- que corrige la línea de código identificada como sospechosa -- empeora el síntoma en vez de resolverlo? No se investigó a fondo.
- ¿Cuál de las alternativas listadas arriba resuelve el crash sin introducir regresiones? Ninguna se probó todavía.
- ¿El bug requiere una profundidad mínima de anidamiento, o cualquier tabla (incluso sin anidar) lo dispara? No se investigó.
