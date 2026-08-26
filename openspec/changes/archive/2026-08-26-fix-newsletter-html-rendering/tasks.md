> **Estado: secciones 1-8 son registro histórico de dos intentos de fix, ambos revertidos** (ver `design.md`). El crash reportado en Sentry seguía sin resolverse al cierre de esa sesión. La **sección 9 es el trabajo pendiente de esta sesión**: un tercer intento (detectar email crudo + renderizar ese subconjunto en WebView) diseñado en `design.md` pero aún sin implementar -- listo para `/opsx:apply`.

## 1. Confirmación de causa raíz (esta sesión, completado)

- [x] 1.1 Revisar Sentry (`reevo-dev`) en busca de crashes relacionados con el reporte original. **Resultado:** 30 issues activos y escalando con la misma firma (`AssertionError: 'hasSize': RenderBox was not laid out`), miles de eventos, en simulador iOS real con Flutter 3.44.6.
- [x] 1.2 Ubicar el origen exacto en el código fuente de `flutter_widget_from_html_core` (stack trace + `debugCreator`). **Resultado:** `_TableRenderLayouter.step3MinIntrinsicWidth` / `ValignBaselineContainer`, aplicado incondicionalmente a todo `<table>` (`tag_table.dart:94`).
- [x] 1.3 Verificar si existe un fix upstream confirmado (changelog `0.15.2` → `0.17.2`, issues del repo). **Resultado:** no se encontró ninguno aplicable a la versión de Flutter actual.
- [x] 1.4 Documentar la evidencia completa en `design.md`.

## 2. Implementación del fix

- [x] 2.1 En `lib/core/widgets/fwh_html_content_renderer.dart`, agregar una función `flattenTables` (o nombre equivalente, `@visibleForTesting` como `stripInlineTextColors`/`normalizeYoutubeUrl`) que reemplace por regex las etiquetas de apertura/cierre `table`, `thead`, `tbody`, `tfoot`, `tr`, `th`, `td`, `caption` por `div`, preservando el resto de atributos y el contenido intacto (ver `design.md`, sección "Decisions").
- [x] 2.2 Aplicar `flattenTables` en `FwhHtmlContentRenderer.build`, junto a `stripInlineTextColors`, antes de pasar el HTML a `HtmlWidget`.
- [x] 2.3 Confirmar manualmente (widget test o script) que el HTML resultante para el fixture real (`test/fixtures/newsletter_nested_tables.html`) ya no contiene ninguna etiqueta `<table>`/`<tr>`/`<td>`/etc. **Resultado:** 0 tags de tabla restantes, 386 `<div>` generados.

## 3. Tests

- [x] 3.1 Test unitario para `flattenTables` en `test/unit/core/widgets/fwh_html_content_renderer_test.dart` (o archivo nuevo si el existente no aplica): casos con tabla simple, tabla anidada, atributos preservados (`style`, `href` dentro de una celda), y que no toca contenido fuera de tags de tabla.
- [x] 3.2 Actualizar `test/widget/core/widgets/fwh_html_content_renderer_newsletter_test.dart` para reflejar el comportamiento con el fix: confirmar que el fixture real (con y sin imágenes) renderiza sin lanzar ninguna excepción de rendering capturable vía `FlutterError.onError`, además de seguir mostrando el contenido de texto esperado ("View Online").
- [x] 3.3 Correr `flutter test` completo y confirmar que no se rompe ningún test existente (en particular los que ya cubren YouTube embeds y `stripInlineTextColors`, dado que ambas transformaciones ahora se aplican en secuencia sobre el mismo HTML). **Resultado:** 441/441 tests pasaron, sin fallas.
- [x] 3.4 Correr `flutter analyze` sin issues. **Resultado:** sin issues.

## 4. Verificación manual

- [x] 4.1 Levantar la app (`flutter run`) y abrir el artículo real de Morning Brew (o cualquier newsletter con tablas anidadas) para confirmar visualmente que el contenido se lee correctamente. **Resultado:** el usuario probó en simulador (Daily Stoic y The Morning Brew); el contenido ya se ve (antes no se veía nada). Reveló un efecto secundario: fondo blanco sólido del newsletter visible contra el dark theme (ver tarea 5).
- [x] 4.2 Revisar que no aparezcan nuevos errores relacionados en Sentry (`reevo-dev`) tras probar el artículo con el fix aplicado. **Resultado:** los issues de `RenderBox was not laid out` quedaron congelados en "last seen" tras el hot restart con el fix -- no se generaron eventos nuevos durante la prueba manual.

## 5. Fondo blanco inline (efecto secundario de desbloquear el render)

Antes del fix, la tabla nunca llegaba a pintarse, así que el `background-color`/`bgcolor` blanco que las tablas de layout de newsletters de marketing traen inline (pensado para el fondo claro por defecto de un cliente de email) nunca se veía. Con el contenido ya renderizando, ese fondo queda como un bloque sólido que choca con el dark theme del lector.

- [x] 5.1 Agregar `stripInlineBackgroundColors` en `lib/core/widgets/fwh_html_content_renderer.dart` (mismo patrón que `stripInlineTextColors`: quita `style="background-color:..."` y el atributo deprecado `bgcolor`, sin tocar `color` ni otras propiedades).
- [x] 5.2 Aplicar `stripInlineBackgroundColors` en `FwhHtmlContentRenderer.build`, junto a `stripInlineTextColors` y `flattenTables`.
- [x] 5.3 Agregar tests unitarios para `stripInlineBackgroundColors` (style inline, atributo `bgcolor`, no toca `color`, no altera elementos sin fondo).
- [x] 5.4 Correr `flutter test` completo y `flutter analyze` de nuevo. **Resultado:** 446/446 tests pasaron, sin issues de analyze.

## 6. Regresión encontrada y revert

- [x] 6.1 Probar el fix contra un newsletter real adicional, distinto del fixture de desarrollo (The Morning Brew, "Oh, Canada", 24 de agosto). **Resultado:** regresión grave -- texto e imágenes completamente superpuestos e ilegibles. Confirmado que el fixture nuevo no usa `rowspan`/`colspan`/`position: absolute`; el problema es estructural a aplanar toda tabla a `<div>` (ver `design.md`).
- [x] 6.2 Revertir `flattenTables`, `stripInlineBackgroundColors` y su aplicación en `FwhHtmlContentRenderer.build`, junto con sus tests unitarios, de vuelta al estado previo a este change (`git checkout` sobre `lib/core/widgets/fwh_html_content_renderer.dart` y `test/unit/core/widgets/fwh_html_content_renderer_test.dart`).
- [x] 6.3 Actualizar `fwh_html_content_renderer_newsletter_test.dart` para no depender de las funciones revertidas -- se mantiene como test de regresión que documenta el estado actual (sin fix) contra el fixture real.
- [x] 6.4 Correr `flutter test` completo y `flutter analyze` tras el revert. **Resultado:** 436/436 tests pasaron (vuelta a la línea base previa a este change), sin issues de analyze.
- [x] 6.5 Documentar la regresión, el revert, y las alternativas no probadas en `design.md` y `proposal.md`.

## 7. Segundo intento: actualizar a flutter_widget_from_html 0.17.2 (también revertido)

- [x] 7.1 Comparar el código fuente de `_TableRenderLayouter.step3MinIntrinsicWidth` entre `0.15.2` y `0.17.2`. **Resultado:** la línea sospechosa (`layouter(child, const BoxConstraints())`, layout sin restricciones) fue reemplazada por `layouter(child, constraints)` en `0.17.2`.
- [x] 7.2 Actualizar `pubspec.yaml` a `flutter_widget_from_html: ^0.17.0` (resuelve `0.17.2`), sin tocar `fwh_html_content_renderer.dart`. Correr `flutter test`/`flutter analyze`. **Resultado:** sin issues, 436/436 tests.
- [x] 7.3 Probar en simulador real contra "Oh, Canada". **Resultado:** el crash persiste y empeora -- loop continuo de excepciones (`AssertionError: 'hasSize'` repetido decenas de veces por segundo, Sentry reportando tasks dropped por exceso de paralelismo), pantalla en blanco sin spinner, nunca estabiliza un frame.
- [x] 7.4 Revertir `pubspec.yaml` a `flutter_widget_from_html: ^0.15.0`. Correr `flutter test`/`flutter analyze`. **Resultado:** 436/436 tests, sin issues, sin diff neto contra el estado previo a esta sesión.
- [x] 7.5 Documentar el segundo intento fallido en `design.md` y `proposal.md`.

## 8. Pendiente de sesiones anteriores (superado por la sección 9)

- [x] 8.1 ~~Elegir y probar una de las alternativas listadas en `design.md`~~ -- superado: se investigó la causa de por qué el HTML tiene esta forma (email crudo vía puentes de email-a-RSS como `kill-the-newsletter.com`, identificable por marcas VML/Office de Outlook) y se diseñó un tercer intento acotado a ese subconjunto. Ver sección 9.

## 9. Tercer intento (propuesto): detectar email crudo y renderizarlo en WebView

### 9.1 Detección

- [x] 9.1.1 En `lib/core/widgets/fwh_html_content_renderer.dart`, agregar `looksLikeRawEmailHtml(String htmlContent)` (`@visibleForTesting`, mismo patrón que `stripInlineTextColors`/`normalizeYoutubeUrl`) que retorna `true` si el HTML contiene `xmlns:v="urn:schemas-microsoft-com:vml"` o `xmlns:o="urn:schemas-microsoft-com:office:office"` (ver `design.md`, sección "Decisión: detectar el patrón en vez de transformar todo el HTML").
- [x] 9.1.2 Tests unitarios para `looksLikeRawEmailHtml`: positivo con el fixture real (`newsletter_nested_tables.html`), positivo con cada marca por separado, negativo con HTML de blog/web típico (`<p>`, `<h2>`, sin namespaces), negativo con HTML vacío/simple.

### 9.2 Widget de WebView para contenido detectado

- [x] 9.2.1 Agregar un widget interno (ej. `_RawEmailWebView`) en el mismo archivo, siguiendo el patrón de `_YoutubeWebView`: `WebViewController()..loadHtmlString(htmlContent, baseUrl: articleUrl)`. Definir si restringe `JavaScriptMode` dado que el contenido viene de un remitente no confiable (ver `design.md`, Riesgos) o si necesita JS habilitado para el `ResizeObserver` de la tarea 9.2.2.
- [x] 9.2.2 Implementar la medición de altura dinámica: inyectar un `ResizeObserver` sobre `document.body` que reporte `scrollHeight` vía `JavaScriptChannel` después de `onPageFinished`, y usar ese valor para dimensionar un `SizedBox` alrededor del `WebViewWidget` con `setState`. Mientras la altura es desconocida, mostrar un placeholder con `CircularProgressIndicator` (mismo tamaño/estilo que el que ya muestra `HtmlWidget` para el resto del contenido).
- [x] 9.2.3 En `FwhHtmlContentRenderer.build`, si `looksLikeRawEmailHtml(htmlContent)` es `true`, renderizar `_RawEmailWebView` con el `htmlContent` sin pasar por `stripInlineTextColors`/`stripInlineBackgroundColors`; si es `false`, mantener el camino actual (`HtmlWidget` + `stripInlineTextColors`) sin cambios.

### 9.3 Tests y verificación

- [x] 9.3.1 Actualizar `fwh_html_content_renderer_newsletter_test.dart`: confirmar que el fixture real, al pasar por `FwhHtmlContentRenderer`, renderiza vía el camino de WebView (no `HtmlWidget`) y no lanza ninguna excepción de rendering.
- [x] 9.3.2 Correr `flutter test` completo y `flutter analyze`. **Resultado:** 440/441 tests (la única falla es `localized_date_formatter_test.dart: muestra hora HH:mm para hoy`, preexistente y no relacionada -- depende de `DateTime.now()`, falla porque la hora local actual no tiene cero-padding). `flutter analyze` sin issues (se agregó `webview_flutter_platform_interface` como dev_dependency para el fake de test).
- [x] 9.3.3 Levantar la app en simulador/dispositivo real y confirmar visualmente. **Resultado:** parcial -- Morning Brew ("Going after ghosts") renderiza correctamente vía WebView. Daily Stoic ("Your Week With Daily Stoic") seguía en blanco: ver sección 10, causa raíz distinta.
- [x] 9.3.4 Confirmar en Sentry (`reevo-dev`) que no aparecen eventos nuevos de `RenderBox was not laid out` tras la prueba manual con Morning Brew. **Resultado:** sin eventos nuevos en la ventana de la prueba (`firstSeen:-90m` vacío); el issue preexistente `REEVO-DEV-1Z` (`'node.built': is not true`) sigue activo pero es ruido de hot-reload en modo debug, no relacionado.
- [x] 9.3.5 Confirmar que un artículo de una fuente normal (sin marcas de email crudo ni tablas profundas) sigue renderizando exactamente igual que antes -- sin cambios de comportamiento fuera del subconjunto detectado. **Resultado:** confirmado por el usuario -- "se ve bien".

## 10. Cuarto intento: Daily Stoic reveló que la detección por marcas VML/Office era insuficiente

Tras confirmar el fix con Morning Brew (sección 9.3.3), el usuario probó un segundo newsletter real vía el mismo puente `kill-the-newsletter.com` -- Daily Stoic, "Your Week With Daily Stoic" (22 de agosto) -- y reportó el mismo síntoma original: contenido completamente en blanco.

- [x] 10.1 Pedir al usuario la Debug Console de VS Code en el momento de abrir el artículo de Daily Stoic. **Resultado:** stack trace idéntico al crash original (`_TableRenderLayouter.step3MinIntrinsicWidth`, `AssertionError: 'hasSize': RenderBox was not laid out`), con el widget causante `HtmlWidget:...fwh_html_content_renderer.dart:342:12` -- el camino **nativo**, no `_RawEmailWebView`. Confirma que `looksLikeRawEmailHtml` devolvió `false` para este contenido: el ESP de Daily Stoic no deja las marcas VML/Office de Outlook que Morning Brew sí deja, pero el HTML igual tiene tablas anidadas lo bastante profundas para disparar el mismo bug de `flutter_widget_from_html_core`.
- [x] 10.2 Ampliar `looksLikeRawEmailHtml` en `lib/core/widgets/fwh_html_content_renderer.dart`: agregar `maxTableNestingDepth` (`@visibleForTesting`, conteo lineal de aperturas/cierres de `<table` vía regex) y un umbral (`_deeplyNestedTableThreshold = 4`) como señal adicional, independiente de las marcas VML/Office -- la causa real del crash es la profundidad de anidamiento en sí, no ningún namespace particular de un ESP específico.
- [x] 10.3 Agregar tests unitarios: `maxTableNestingDepth` (sin tablas, anidamiento simple, tablas hermanas no anidadas, HTML mal formado con cierres de más) y `looksLikeRawEmailHtml` (anidamiento profundo sin marcas VML/Office detecta `true`; tablas de datos con poco anidamiento no disparan falso positivo).
- [x] 10.4 Correr `flutter test` (archivos afectados) y `flutter analyze`. **Resultado:** 27/27 tests pasaron, `flutter analyze` sin issues.
- [x] 10.5 Repetir la verificación manual contra Daily Stoic con el umbral de anidamiento aplicado. **Resultado:** el crash desapareció (la detección amplia funcionó) pero surgió un problema nuevo -- ver sección 11.

## 11. Quinto intento: contenido "alejado" (zoom-out) en el WebView de Daily Stoic

Con la detección de tablas profundas activa, Daily Stoic ya renderiza vía `_RawEmailWebView` sin crashear, pero el usuario reportó el contenido con aspecto de "zoom out": texto diminuto y márgenes vacíos a los costados.

- [x] 11.1 Diagnóstico: WebKit renderiza HTML sin una etiqueta `<meta name="viewport">` asumiendo un viewport virtual de escritorio (~980px) y escala toda la página para que quepa en el ancho real de la pantalla -- exactamente el síntoma reportado. Morning Brew no mostró el problema porque su HTML sí trae esa etiqueta; el ESP de Daily Stoic no la incluye.
- [x] 11.2 Agregar `ensureViewportMeta(String htmlContent)` en `lib/core/widgets/fwh_html_content_renderer.dart` (`@visibleForTesting`): si el HTML no trae ya una etiqueta `<meta name="viewport">` (detectada con comillas simples o dobles), inserta `<meta name="viewport" content="width=device-width, initial-scale=1.0">` justo después de `<head>`, o al inicio del documento si no hay `<head>`. No toca el HTML si ya trae su propia etiqueta viewport.
- [x] 11.3 Aplicar `ensureViewportMeta` en `_RawEmailWebViewState.initState`, envolviendo `widget.htmlContent` antes de `loadHtmlString`.
- [x] 11.4 Tests unitarios para `ensureViewportMeta`: inserta después de `<head>`, antepone si no hay `<head>`, no toca HTML que ya trae viewport (comillas dobles y simples).
- [x] 11.5 Correr `flutter test` (archivos afectados) y `flutter analyze`. **Resultado:** 31/31 tests pasaron, `flutter analyze` sin issues.
- [x] 11.6 Confirmar en dispositivo real que Daily Stoic ahora renderiza a tamaño correcto (sin zoom-out). **Resultado:** confirmado por el usuario -- tamaño correcto.

## 12. Sexto pedido (preferencia visual, no bug): fondo blanco del email choca con el dark theme

El usuario, ya con el tamaño corregido, pidió atenuar el choque visual del fondo blanco propio del email contra el dark theme de la app -- explícitamente sin forzar colores dentro del contenido (eso ya se descartó por el motivo documentado en la clase `_RawEmailWebView`: el texto del email está calibrado para su propio fondo, forzar dark rompería el contraste).

- [x] 12.1 Investigar convenciones existentes de la app para contenedores con esquinas redondeadas y borde, para no introducir un estilo nuevo. **Resultado:** `add_source_screen.dart` usa `Card`/`RoundedRectangleBorder` con radio **12** y borde `colorScheme.outlineVariant`, sin elevación -- único precedente en el código (no hay radios de 8 o 16 en uso). `ChamferedBox` es un estilo geométricamente distinto (esquina cortada en diagonal, no redondeada) y no aplica acá.
- [x] 12.2 Envolver `_RawEmailWebView` en un `Container` con `clipBehavior: Clip.antiAlias` y `BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outlineVariant))`, mismo tratamiento que las tarjetas existentes -- el fondo blanco del email queda enmarcado como una tarjeta con su propio diseño, en vez de chocar directamente contra el fondo oscuro de la pantalla.
- [x] 12.3 Correr `flutter test` (archivos afectados) y `flutter analyze`. **Resultado:** 31/31 tests pasaron, sin issues de analyze.
- [x] 12.4 Confirmar visualmente en dispositivo real que la tarjeta se ve consistente con el resto del dark theme de la app. **Resultado:** confirmado por el usuario -- "se ve bien".
