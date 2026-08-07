## Why

Los artículos cuyo HTML incluye un video embebido de YouTube (`<iframe src="youtube.com/embed/...">`) muestran "Error 153 - Video player configuration error" en vez de reproducir el video. El WebView aislado que usa la app para renderizar el iframe carga la URL tal cual vino del feed original, con un parámetro `origin` que apunta al dominio del sitio de origen — un dominio que no coincide con el contexto real (un WebView nativo dentro de la app), lo que hace que YouTube rechace la reproducción.

## What Changes

- Al renderizar el HTML de un artículo, si el `<iframe>` embebido apunta a YouTube (`youtube.com`, `youtube-nocookie.com`, o `youtu.be`), la URL se normaliza antes de cargarla en el WebView: se quita el parámetro `origin` (la causa del Error 153, ya que no hay ningún dominio real que lo justifique en este contexto) y se convierte el formato deprecado `/v/<id>` (o los links cortos `youtu.be/<id>`) al formato `/embed/<id>`. Cualquier otro iframe (no-YouTube) sigue cargándose sin cambios.
- **Corrección de una violación de arquitectura preexistente, necesaria para implementar el fix en el lugar correcto**: `lib/features/reader/presentation/screens/reader_screen.dart` importa `flutter_widget_from_html` directamente y usa `HtmlWidget` sin pasar por la abstracción `HtmlContentRenderer` que ya existe en `core/widgets/` (violando la regla de abstracciones de CLAUDE.md). Se lo migra para que use `FwhHtmlContentRenderer` (la implementación concreta ya existente pero hoy sin ningún caller), que pasa a ser el único punto del código que sabe de `flutter_widget_from_html` y por lo tanto el lugar natural para la normalización de URLs de YouTube.

## Capabilities

### New Capabilities

- `article-html-rendering`: cubre cómo se renderiza el HTML del contenido de un artículo dentro del lector, incluyendo el manejo de iframes embebidos de YouTube.

### Modified Capabilities

(ninguna)

## Impact

- `lib/core/widgets/fwh_html_content_renderer.dart`: agrega un `WidgetFactory` personalizado que normaliza URLs de iframes de YouTube antes de delegar en el `WebView` por defecto de `fwfh_webview`.
- `lib/features/reader/presentation/screens/reader_screen.dart`: deja de importar `flutter_widget_from_html` directamente; usa `FwhHtmlContentRenderer` en su lugar.
- `test/widget/features/reader/reader_screen_test.dart`: sin cambios esperados en las aserciones existentes (siguen encontrando un `HtmlWidget` en el árbol, ahora anidado dentro de `FwhHtmlContentRenderer`).
