## Why

Hoy la alternativa de "generar dirección de email" para newsletters sin RSS solo aparece como una acción dentro del `SnackBar` de error de detección, sin espacio para explicar qué hace ni por qué usarla. El usuario tiene que fallar primero un intento de detección para siquiera enterarse de que existe esa opción, y una vez que la ve, no tiene contexto sobre el valor de la feature (que los correos entrantes se conviertan en artículos).

## What Changes

- **BREAKING (UX)**: se quita el botón de acción "Generar email" del `SnackBar` de error de `AddSourceFeedDiscoveryFailed`; el snackbar pasa a ser un aviso puro sin acción.
- `AddSourceScreen` agrega una sección "Otras formas de agregar" debajo del botón "Agregar", con dos cards siempre visibles:
  - "Importar desde OPML": sin cambios de comportamiento respecto a hoy (solo se reubica visualmente como card).
  - "Generar dirección de email": nueva card colapsable con ícono `mail_outline`, título y descripción breve. Al tocarla se expande (con `AnimatedSize`) mostrando una explicación más completa y un botón interno "Generar dirección de email" que dispara el flujo existente (`generateEmailFeed()` → spinner → diálogo con la dirección generada).
  - La card de email se auto-colapsa al generar la dirección exitosamente, o al agregar una fuente exitosamente por cualquier vía (URL u OPML).

## Capabilities

### New Capabilities

_(ninguna)_

### Modified Capabilities

- `source-management`: el requirement "AddSourceScreen ofrece generar un email cuando falla la detección automática" cambia de fondo — la opción deja de depender del fallo de detección y pasa a ser una card siempre visible y colapsable en la pantalla, con el snackbar de error ya sin acción asociada.

## Impact

- `lib/features/sources/presentation/screens/add_source_screen.dart`: layout de la pantalla (nueva sección de cards), estado de expandido/colapsado de la card de email, y el `SnackBar` de error de detección (se le quita la acción).
