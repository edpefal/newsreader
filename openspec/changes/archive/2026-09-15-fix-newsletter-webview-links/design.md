## Context

`_RawEmailWebView` (`lib/core/widgets/fwh_html_content_renderer.dart`) usa `WebViewController.setNavigationDelegate` con un flag `_initialLoadDone`: hasta que `onPageFinished` dispara por primera vez, cualquier `onNavigationRequest` se permite (es la carga inicial del propio HTML del email vía `loadHtmlString`); después de eso, cualquier `onNavigationRequest` se descarta con `NavigationDecision.prevent`. Eso incluye tanto navegaciones indeseadas (ej. "Unsubscribe" secuestrando la pantalla) como taps legítimos en links del contenido, que quedan indistinguibles entre sí con la lógica actual.

`ExternalLinkLauncher` (`core/navigation/external_link_launcher.dart`) ya es la abstracción del proyecto para abrir una URL en el navegador del sistema (regla de abstracciones: `url_launcher` nunca se importa fuera de su implementación concreta). Ya está registrada en `core/di/injection.dart` como singleton y se inyecta hoy en `ReaderScreen` y `ArticleSummaryBottomSheet`. Ver proposal.md para el motivo del cambio.

## Goals / Non-Goals

**Goals:**
- Que un tap en un link del HTML de un email reenviado abra esa URL en el navegador externo, sin que el `WebView` embebido navegue a ella.
- Mantener sin cambios la carga inicial del HTML del email y el resto del comportamiento de `_RawEmailWebView` (resize observer, script stripping, viewport meta).

**Non-Goals:**
- No se toca `WebviewFlutterArticleWebView` (la vista de "ver artículo original"): ya permite navegación libre porque ahí el usuario está viendo el sitio real, no un email de remitente no confiable.
- No se toca el otro camino de renderizado (`HtmlWidget` vía `flutter_widget_from_html` para HTML que no es email crudo): sus links ya se manejan por el comportamiento default de `flutter_widget_from_html`, que no pasa por `_RawEmailWebView`. Confirmar en tasks si ese camino ya abre links correctamente o si queda fuera de este fix por no reproducir el bug reportado.

## Decisions

**Interceptar en `onNavigationRequest` y delegar a `ExternalLinkLauncher`, en lugar de remover el bloqueo de navegación.**
Alternativa descartada: dejar que el `WebView` navegue libremente tras la carga inicial. Se descarta porque el HTML viene de un remitente no confiable (ver comentario existente sobre `stripScriptExecutionVectors`) y porque esta pantalla no tiene barra de navegación ni botón "atrás" propio del `WebView` — un link tipo "Unsubscribe" seguiría secuestrando la pantalla sin forma de volver. Abrir en el navegador externo preserva la protección original y hace el link útil.

**Propagar `ExternalLinkLauncher` por constructor desde `ReaderScreen`, no vía `getIt` dentro de `fwh_html_content_renderer.dart`.**
Sigue la regla de abstracciones del proyecto (`get_it` solo se llama en `core/di/injection.dart`). `HtmlContentRenderer` (clase abstracta en `core/widgets/`) gana un campo `required ExternalLinkLauncher externalLinkLauncher`; `FwhHtmlContentRenderer` lo pasa a `_RawEmailWebView`. `ReaderScreen` ya recibe `externalLinkLauncher` por constructor (inyectado desde `router.dart` vía `getIt<ExternalLinkLauncher>()`), así que solo hace falta pasarlo en la construcción de `FwhHtmlContentRenderer` en `_buildContent`.

**Distinguir la carga inicial reutilizando el flag `_initialLoadDone` ya existente.**
No se necesita lógica nueva de detección: la construcción de `onNavigationRequest` ya diferencia "es la primera carga" de "es una navegación posterior". El único cambio es qué hacer en la rama "posterior": antes `NavigationDecision.prevent` sin más; ahora, además, `externalLinkLauncher.open(request.url)` antes de retornar `prevent`.

## Risks / Trade-offs

[Un email con múltiples navegaciones internas legítimas antes de terminar de cargar (ej. redirects del propio email) podría no distinguirse de "carga inicial" vs "tap real"] → Es el mismo riesgo que ya existía en el código actual con el bloqueo total; no se introduce comportamiento nuevo en ese caso límite, solo se cambia qué pasa con las navegaciones que sí se bloquean.

[`ExternalLinkLauncher.open` puede fallar silenciosamente si la URL no tiene un manejador en el disposito] → Ya es el comportamiento actual de `UrlLauncherExternalLinkLauncher` en el resto de la app (ej. desde `ArticleSummaryBottomSheet`); no se introduce manejo de error especial aquí, para mantener consistencia con esos otros usos.
