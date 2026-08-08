## Why

Cuando un feed no publica el contenido completo del artículo (ej. `tldr.tech`, cuyo RSS solo trae título y link, sin `<description>` ni `<content:encoded>`), el lector muestra "Contenido no disponible en el feed." sin mencionar que existe una forma de leerlo: el ícono "Ver en navegador" en el AppBar, que abre el artículo original en el WebView embebido. El usuario no tiene forma de saber que esa opción existe salvo que la descubra por su cuenta.

Además, la regla de truncamiento ya definida en `FeedContentChecker.isTruncated()` (`contentHtml` nulo, vacío, o menor a 500 caracteres — el umbral que ya usa `GenerateDailySummary`) no se usa hoy en el lector: `ReaderScreen._buildContent` solo chequea `contentHtml != null`, así que un artículo con contenido parcial muy corto (ej. un teaser de 80 caracteres antes de un paywall) no recibe ningún aviso, aunque sí califica como truncado según esa misma regla.

## What Changes

- El lector usa `FeedContentChecker.isTruncated(article.contentHtml)` (ya existente, hoy sin uso en el lector) para decidir si mostrar un aviso, en vez de solo chequear `contentHtml != null`.
- Cuando el contenido está truncado (nulo, vacío, o corto), se muestra un aviso debajo del contenido disponible (excerpt o HTML corto, si hay) o en su lugar (si no hay nada), indicando que el feed no trae el artículo completo.
- Ese aviso es tocable: al tocarlo, navega a la misma pantalla de WebView que ya abre el ícono del AppBar (`/article/:id/web`) — no es solo texto informativo, es una acción.
- Se quita el mensaje genérico actual "Contenido no disponible en el feed." (queda reemplazado por el aviso nuevo, que cubre el mismo caso más el de contenido corto).

## Capabilities

### New Capabilities

- `article-content-fallback`: qué se le muestra al usuario en el lector cuando el contenido de un artículo está truncado o ausente, y cómo accede a la alternativa de leerlo en el sitio original.

### Modified Capabilities

(ninguna — no hay spec existente que documente el comportamiento actual del lector ante contenido truncado/ausente)

## Impact

- `lib/features/reader/presentation/screens/reader_screen.dart`: `_buildContent` pasa a usar `FeedContentChecker.isTruncated`, agrega el aviso tocable, quita el mensaje genérico actual.
- Tests de `test/widget/features/reader/reader_screen_test.dart` (si existe) o nuevo archivo de test a agregar/extender.
- No afecta al AppBar ni al ícono "Ver en navegador" existente — el aviso nuevo navega a la misma ruta que ya usa ese ícono.
