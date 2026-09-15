## Why

Cuando un artículo proviene de un email de marketing/newsletter reenviado (detectado como "email crudo", ver `article-html-rendering`), se renderiza dentro de un `WebView` embebido (`_RawEmailWebView`). Ese `WebView` bloquea toda navegación posterior a la carga inicial (`onNavigationRequest` devuelve `NavigationDecision.prevent`) para evitar que un link (ej. "Unsubscribe") secuestre la pantalla del lector. Pero ese bloqueo es total: cualquier link legítimo del newsletter (un artículo referenciado, un producto, una fuente citada) tampoco hace nada al tocarlo, sin ningún feedback al usuario. El contenido de una newsletter suele depender de esos links para ser útil, así que el comportamiento actual rompe un caso de uso central de esos artículos.

## What Changes

- En `_RawEmailWebView`, reemplazar el bloqueo total de navegación por una intercepción: cuando el usuario toca un link dentro del email (una navegación distinta de la carga inicial), abrirlo en el navegador externo del sistema vía `ExternalLinkLauncher` en lugar de descartarlo en silencio, y seguir previniendo que el `WebView` embebido navegue a esa URL.
- La carga inicial del HTML del email (`loadHtmlString`) sigue sin verse afectada por este cambio.

## Capabilities

### Modified Capabilities
- `article-html-rendering`: un tap en un link dentro del HTML de un email reenviado ahora abre esa URL en el navegador externo del sistema, en lugar de no hacer nada.

## Impact

- `lib/core/widgets/fwh_html_content_renderer.dart` (`_RawEmailWebView`/`_RawEmailWebViewState`): cambia el `onNavigationRequest` y pasa a depender de `ExternalLinkLauncher`.
- `lib/core/di/injection.dart`: `FwhHtmlContentRenderer`/`_RawEmailWebView` necesita acceso a la implementación registrada de `ExternalLinkLauncher` (ya usada en otro punto de la app, ver `core/navigation/external_link_launcher.dart`).
- Sin cambios en `HtmlContentRenderer` (abstracción) ni en el resto de artículos (los que se renderizan como widgets nativos vía `HtmlWidget` no pasan por este código).
