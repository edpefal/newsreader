## Why

El texto del cuerpo de un artículo en el lector se muestra con un tamaño de fuente pequeño (15px, `bodyMedium`), lo que dificulta la lectura cómoda, especialmente en artículos largos. `FwhHtmlContentRenderer` ya tiene un modo `readerMode` pensado para usar una tipografía más grande (18px) y con mejor interlineado, pero `ReaderScreen` nunca lo activa, por lo que ese estilo nunca se aplica en la práctica. Aumentar el tamaño de fuente mejora la legibilidad sin requerir cambios en la estructura de la app.

## What Changes

- Activar `readerMode: true` al renderizar el HTML del cuerpo de un artículo en `ReaderScreen`, para que use la tipografía dedicada del lector en vez de `bodyMedium`.
- Aumentar el tamaño de fuente de ese modo lector de 18px a un tamaño mayor que mejore la legibilidad.
- Mantener el `height` (interlineado) y `letterSpacing` proporcionalmente coherentes con el nuevo tamaño de fuente.
- No modificar el tamaño de fuente usado fuera del lector (listas de artículos, previews u otro texto que use `bodyMedium`/`bodyLarge` directamente).

## Capabilities

### New Capabilities
- `reader-typography`: Define el tamaño y estilo de tipografía con el que se renderiza el texto del cuerpo de un artículo dentro del lector.

### Modified Capabilities
(ninguna — no hay spec existente para el tamaño de fuente del lector)

## Impact

- `lib/core/widgets/fwh_html_content_renderer.dart`: ajustar el `fontSize` (y posiblemente `height`/`letterSpacing`) del `textStyle` usado cuando `readerMode` es `true`.
- `lib/features/reader/presentation/screens/reader_screen.dart`: pasar `readerMode: true` al construir `FwhHtmlContentRenderer` para el cuerpo del artículo.
- Sin impacto en modelos de datos, persistencia ni otras features. El raw email HTML (renderizado en `WebView`) no se ve afectado.
