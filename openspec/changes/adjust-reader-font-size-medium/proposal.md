## Why

El tamaño de fuente del cuerpo del artículo en el lector (20px, activado en `add-reader-mode`/`increase-reader-font-size`) resultó demasiado grande en el uso real. Antes de ese change el tamaño efectivo era 15px (`bodyMedium`, nunca se activaba `readerMode`), que se consideró chico. El usuario pide un término medio entre ambos extremos.

## What Changes

- Reducir el `fontSize` del modo lector (`readerMode: true`) de 20px a 18px en `FwhHtmlContentRenderer`.
- Mantener `readerMode: true` activo en `ReaderScreen` (sin cambios ahí).
- Ajustar `height` (interlineado) proporcionalmente si hace falta para que siga siendo cómodo con el nuevo tamaño; `letterSpacing` se mantiene igual salvo que la lectura visual indique lo contrario.
- No modificar el tamaño de fuente fuera del lector (listas de inbox, archivo, favoritos).

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
(ninguna — el requisito de `reader-typography` ya dice "mayor al usado en las listas", sin fijar un valor exacto; 18px sigue cumpliéndolo. Es un cambio de valor de implementación, no de requirement. `skip_specs: true` en este change.)

## Impact

- `lib/core/widgets/fwh_html_content_renderer.dart:483`: cambiar `fontSize: 20` a `fontSize: 18` (y revisar `height`/`letterSpacing` en la misma línea) en el branch `readerMode: true`.
- Sin impacto en modelos de datos, persistencia, otras features, ni en el renderizado de email crudo (`_RawEmailWebView`).
