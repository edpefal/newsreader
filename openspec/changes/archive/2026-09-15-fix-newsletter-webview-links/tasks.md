## 1. Propagar `ExternalLinkLauncher` hasta `_RawEmailWebView`

- [x] 1.1 Agregar `required ExternalLinkLauncher externalLinkLauncher` a `HtmlContentRenderer` (`lib/core/widgets/html_content_renderer.dart`).
- [x] 1.2 Agregar el mismo campo al constructor de `FwhHtmlContentRenderer` y pasarlo a `_RawEmailWebView` cuando `looksLikeRawEmailHtml(htmlContent)` es verdadero.
- [x] 1.3 Agregar `required ExternalLinkLauncher externalLinkLauncher` a `_RawEmailWebView`/`_RawEmailWebViewState`.
- [x] 1.4 En `ReaderScreen._buildContent`, pasar `externalLinkLauncher: widget.externalLinkLauncher` (ya disponible como campo del widget) al construir `FwhHtmlContentRenderer`.

## 2. Abrir links tocados en el navegador externo

- [x] 2.1 En `_RawEmailWebViewState.initState`, modificar el `onNavigationRequest` del `NavigationDelegate`: cuando `_initialLoadDone` es `true` (navegación posterior a la carga inicial), llamar a `externalLinkLauncher.open(request.url)` antes de retornar `NavigationDecision.prevent`, en vez de solo retornar `prevent`.
- [x] 2.2 Confirmar que la rama de carga inicial (`_initialLoadDone` en `false`) sigue retornando `NavigationDecision.navigate` sin cambios.

## 3. Verificar el otro camino de renderizado

- [x] 3.1 Confirmar (leyendo `flutter_widget_from_html`/`fwfh_webview` o con una prueba manual documentada) si los links en artículos que NO son email crudo (renderizados vía `HtmlWidget`) ya abren correctamente el link por fuera de la app; si no es así, decidir con el usuario si ese caso entra en el alcance de este change o queda para uno aparte.

## 4. Tests

- [x] 4.1 Agregar/actualizar un widget test de `fwh_html_content_renderer.dart` (o el archivo de test existente que cubre `_RawEmailWebView`) que verifique: una navegación posterior a la carga inicial invoca `externalLinkLauncher.open` con la URL tocada, y no navega el `WebView` embebido.
- [x] 4.2 Correr `flutter analyze` y `flutter test` localmente; confirmar que no quedan warnings.
