## 1. Normalización de URLs de YouTube

- [x] 1.1 En `lib/core/widgets/fwh_html_content_renderer.dart`, agregar la función privada `_normalizeYoutubeUrl(String url)` que detecta iframes de `youtube.com`, `www.youtube.com`, `youtube-nocookie.com`, `www.youtube-nocookie.com` y `youtu.be`, extrae el `videoId` de los formatos `/embed/<id>`, `/v/<id>` y `youtu.be/<id>`, y retorna la URL normalizada a `https://<host>/embed/<id>` sin el parámetro `origin` (o `null` si la URL no es reconocible como YouTube).
- [x] 1.2 Agregar la clase privada `_ArticleWidgetFactory extends WidgetFactory with WebViewFactory` que sobreescribe `buildWebView` para usar `_normalizeYoutubeUrl(url) ?? url` antes de delegar en `super.buildWebView`.
- [x] 1.3 Pasar `factoryBuilder: () => _ArticleWidgetFactory()` al `HtmlWidget` dentro de `FwhHtmlContentRenderer.build()`.

## 2. Migrar reader_screen.dart a la abstracción

- [x] 2.1 En `lib/features/reader/presentation/screens/reader_screen.dart`, quitar el import directo de `flutter_widget_from_html` y agregar el import de `FwhHtmlContentRenderer` desde `core/widgets/`.
- [x] 2.2 En `_buildContent`, reemplazar `HtmlWidget(article.contentHtml!, textStyle: theme.textTheme.bodyMedium)` por `FwhHtmlContentRenderer(htmlContent: article.contentHtml!)`.

## 3. Tests

- [x] 3.1 Agregar un test unitario para `_normalizeYoutubeUrl` (o la función equivalente expuesta para testing) cubriendo: URL `/embed/<id>` con `origin` (se quita el parámetro, mismo `videoId`), URL `/v/<id>` (se convierte a `/embed/<id>`), URL `youtu.be/<id>` (se convierte a `https://www.youtube.com/embed/<id>`), y una URL de un dominio no-YouTube (retorna `null`, sin modificar).
- [x] 3.2 Correr `test/widget/features/reader/reader_screen_test.dart` y confirmar que las aserciones existentes (`find.byType(HtmlWidget)`) siguen pasando sin modificaciones.

## 4. Verificación final

- [x] 4.1 Correr `flutter analyze` y confirmar que no hay warnings (en particular, que ya no queda ningún import directo de `flutter_widget_from_html` fuera de `core/widgets/`).
- [x] 4.2 Correr `flutter test` (suite completa) y confirmar que todo pasa.
- [x] 4.3 Verificación manual: abrir en el lector un artículo real con un iframe de YouTube embebido (como el del reporte original, "Oso Trava Daily") y confirmar que el video se reproduce sin el Error 153. **Resultado en este primer intento: seguía fallando** — ver sección 5. Confirmado exitoso recién en la tercera iteración (6.6).

## 5. Segunda iteración — header Referer (agregada tras verificar que 4.3 seguía fallando)

La verificación 4.3 mostró que limpiar la URL no alcanzaba: "Ver en navegador" (navegación completa, con `Referer` natural) reproduce el video bien; el modo lector (navegación aislada sin `Referer`) seguía fallando. Ver design.md - Decisión 4.

- [x] 5.1 En `lib/core/widgets/fwh_html_content_renderer.dart`, agregar el widget privado `_YoutubeWebView` (`StatefulWidget` con `webview_flutter`) que carga la URL normalizada vía `WebViewController.loadRequest(uri, headers: {'Referer': 'https://www.youtube.com/'})`, respetando el aspect ratio de `height`/`width` cuando estén disponibles (igual que hace `fwfh_webview` por defecto, `16/9` si no).
- [x] 5.2 En `_ArticleWidgetFactory.buildWebView`, para iframes de YouTube devolver `_YoutubeWebView` directamente en vez de delegar en `super.buildWebView` con la URL limpia; para cualquier otro iframe, seguir delegando en `super.buildWebView` sin cambios.
- [x] 5.3 Correr `flutter analyze` y `flutter test` (suite completa) de nuevo y confirmar que no hay regresiones.
- [x] 5.4 Verificación manual (segunda ronda): repetir 4.3 con el mismo artículo y confirmar si el video ahora se reproduce. **Resultado: empeoró** — pasó de "Error 153 (configuration error)" a "This video is unavailable — Error code: 152-4". Se descarta el header `Referer` inventado (ver design.md, actualización de Decisión 4).

## 6. Tercera iteración — iframe real anidado vía loadHtmlString (agregada tras verificar que 5.4 empeoró el error)

Investigación externa encontró un caso idéntico ya resuelto (FreshRSS, lector RSS con el mismo problema): la solución fue agregar `referrerpolicy="strict-origin-when-cross-origin"` a un `<iframe>` real, no un header inventado en una navegación de nivel superior. Ver design.md - Decisión 4 (revisada).

- [x] 6.1 En `lib/core/widgets/fwh_html_content_renderer.dart`, agregar el parámetro `articleUrl` (`String`, requerido) a `FwhHtmlContentRenderer`.
- [x] 6.2 En `lib/features/reader/presentation/screens/reader_screen.dart`, pasar `articleUrl: article.articleUrl` al construir `FwhHtmlContentRenderer`.
- [x] 6.3 Reescribir `_YoutubeWebView` para que reciba `embedUrl` y `baseUrl` (en vez de una sola `url`), construya el documento HTML wrapper con el iframe real (`referrerpolicy="strict-origin-when-cross-origin"`, `allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"`, `allowfullscreen`), y lo cargue vía `_controller.loadHtmlString(html, baseUrl: baseUrl)` en vez de `loadRequest`.
- [x] 6.4 Propagar `articleUrl` desde `_ArticleWidgetFactory` (constructor) hasta `_YoutubeWebView` como `baseUrl`.
- [x] 6.5 Correr `flutter analyze` y `flutter test` (suite completa) de nuevo y confirmar que no hay regresiones (en particular, que el test de `reader_screen_test.dart` no rompe por el nuevo parámetro requerido).
- [x] 6.6 Verificación manual (tercera ronda): repetir con el mismo artículo y confirmar si el video ahora se reproduce. **Resultado: funcionó.**
