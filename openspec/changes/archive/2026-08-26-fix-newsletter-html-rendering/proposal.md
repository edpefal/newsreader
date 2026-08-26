## Why

Algunas fuentes (reportado con The Morning Brew, recibida vía un servicio de email-a-RSS como killthenewspaper) mostraban el lector completamente vacío debajo del divider, como si el artículo no tuviera contenido. Una sesión anterior investigó dos hipótesis con un test de widget usando el HTML real del artículo reportado ("Going after ghosts", Aug 22, 2026; ~94 KB, tablas anidadas en hasta 9 niveles) y **ambas quedaron descartadas por evidencia directa** (ver `design.md`, sección "Investigación previa"): el contenido sí termina renderizándose, y sí hay un indicador de carga por defecto. Esa sesión dejó como pista abierta, sin confirmar, unas excepciones de rendering (`computeDryBaseline`, `RenderBox was not laid out`) observadas en frames posteriores al render correcto.

Esta sesión retomó esa pista y **confirmó la causa raíz con evidencia de producción**: Sentry (proyecto `reevo-dev`) tiene 30 issues activos y escalando, miles de eventos, el más reciente a minutos de esta investigación, todos con la misma firma (`AssertionError: 'hasSize': RenderBox was not laid out`) ocurriendo durante `performLayout()` en un simulador iOS real (Flutter 3.44.6, build 1.8.0+9).

El stack trace y el `debugCreator` de esos eventos apuntan a `_TableRenderLayouter.step3MinIntrinsicWidth` (en `flutter_widget_from_html_core`, `html_table.dart`) y a `ValignBaselineContainer`/`_ValignBaselineClearerRenderObject`. Se confirmó en el código fuente del paquete (`tag_table.dart:94`) que **todo `<table>` se envuelve incondicionalmente en `ValignBaselineContainer`**, sin importar si algún `<td>` usa `vertical-align: baseline` — por eso el fixture de Morning Brew (que solo usa `valign="middle"`) también dispara el mismo mecanismo. Con tablas anidadas profundas, el algoritmo de ancho intrínseco de esa librería consulta el tamaño de RenderObjects hijos que Flutter aún no terminó de layoutear, lo que dispara un `AssertionError` fatal que **corrompe el layout de toda la pantalla del lector** (la cascada de "not laid out" sube hasta el `Scaffold`/`Stack`, no solo el árbol del contenido) — coincide exactamente con el reporte original de "lector completamente vacío, sin spinner".

No se encontró un issue equivalente abierto en el repo de `flutter_widget_from_html` para la versión actual (`0.15.x`) contra Flutter 3.44.6, ni una entrada de changelog confirmando un fix entre `0.15.x` y la última versión (`0.17.2`) — no es seguro asumir que actualizar el paquete resuelve esto sin poder validarlo contra el mismo fixture.

### Por qué el HTML es así: es un email crudo, no contenido web

El fixture real (`test/fixtures/newsletter_nested_tables.html`) tiene marcas inequívocas de que es un **email de marketing crudo**, no HTML pensado para lectores: `xmlns:v="urn:schemas-microsoft-com:vml"` y `xmlns:o="urn:schemas-microsoft-com:office:office"` (namespaces VML que solo existen para sobrevivir al motor de renderizado de Word que usa Outlook de escritorio), `<meta name="x-apple-disable-message-reformatting">` (hack específico de Apple Mail), `<meta http-equiv="X-UA-Compatible" content="IE=edge">` (hack de compatibilidad de Internet Explorer). Estas marcas nunca aparecen en HTML generado para la web.

Esto explica por qué el bug es específico de fuentes suscritas vía un puente de email-a-RSS como `kill-the-newsletter.com`: ese tipo de servicio reenvía el email crudo tal cual como contenido del feed, sin limpiarlo. Un feed RSS nativo (el que un blog o publicación genera desde su propia web) usa HTML semántico normal y nunca tiene tablas anidadas a 9 niveles -- esa profundidad es exclusiva del hack de compatibilidad con Outlook que estas herramientas de email marketing generan.

Esto abre una estrategia de fix mucho más acotada que las dos intentadas antes: en vez de transformar **todo** el contenido HTML (lo que rompió layouts reales en "Oh, Canada"), se puede **detectar específicamente el patrón de email crudo** y cambiar la estrategia de render **solo** para ese subconjunto de artículos -- dejando el 100% del resto del contenido (la gran mayoría de las fuentes) completamente intacto.

## What Changes

**Tercer intento (propuesto en esta sesión, pendiente de `/opsx:apply`).** Los dos intentos anteriores (documentados en `design.md`, ambos revertidos) intentaban resolver el crash transformando el HTML para que seguidera pasando por `flutter_widget_from_html`. Este intento cambia de estrategia: para el subconjunto de artículos identificado como email crudo, **no se intenta convertir el HTML a widgets nativos** -- se renderiza directamente en un `WebView` (vía `webview_flutter`, ya una dependencia existente del proyecto, usada hoy para "Ver en navegador" y para los embeds de YouTube en este mismo archivo). Un motor de browser real no tiene el bug de `_TableRenderLayouter` porque tablas anidadas es exactamente lo que estos motores están hechos para resolver.

- Se agrega una función de detección (`looksLikeRawEmailHtml` o nombre equivalente) en `lib/core/widgets/fwh_html_content_renderer.dart` que identifica el patrón de email crudo por sus marcas características (`xmlns:v="urn:schemas-microsoft-com:vml"`, `xmlns:o="urn:schemas-microsoft-com:office:office"`, `x-apple-disable-message-reformatting`).
- Cuando se detecta, `FwhHtmlContentRenderer.build` renderiza el HTML en un `WebView` vía `loadHtmlString` (mismo patrón que `_YoutubeWebView` ya usa en este archivo) en vez de `HtmlWidget`. El contenido se muestra con su diseño y colores originales del email (sin `stripInlineTextColors`/`stripInlineBackgroundColors`) -- ver `design.md` para por qué esto es aceptable para este subconjunto específico.
- Cuando no se detecta (la inmensa mayoría de los artículos), el comportamiento no cambia en absoluto: sigue siendo `HtmlWidget` con `stripInlineTextColors`, exactamente como hoy.
- Se agrega un test de regresión que confirma que el fixture real ("Going after ghosts") se detecta como email crudo y renderiza sin la excepción de Sentry, y tests unitarios para la función de detección (positivos y negativos, incluyendo HTML normal de blog/web que no debe activar el WebView).

Ver `design.md` para el detalle de los dos intentos anteriores revertidos, la evidencia técnica completa, y las decisiones de diseño de este tercer intento (en particular cómo se integra un `WebView` de altura dinámica dentro del `SingleChildScrollView` del lector sin romper el resto de la pantalla).

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

(ninguna — el comportamiento visible es "el artículo se lee" en vez de "pantalla en blanco" para un subconjunto de fuentes; no hay una capability de producto formalizada para esto más allá de la corrección de un bug)

## Impact

- Código: `lib/core/widgets/fwh_html_content_renderer.dart` (función de detección + nuevo widget interno basado en `WebView` para el contenido detectado como email crudo).
- Tests: nuevo test de regresión con el fixture real confirmando que ya no lanza la excepción de Sentry; tests unitarios para la función de detección.
- Sin cambios en el modelo de datos ni en otras features. No afecta a artículos que no cumplan el patrón de detección (la mayoría).
