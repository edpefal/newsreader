## Why

En la vista de lectura de un artículo (`ReaderScreen`), el usuario hace scroll sobre contenido HTML de longitud variable sin ninguna referencia visual de cuánto ha avanzado ni cuánto le falta. Un indicador de progreso de scroll da esa referencia al instante, sin requerir interacción adicional.

## What Changes

- Agregar una barra de progreso vertical fija (scrollbar/indicador de progreso) en `ReaderScreen` que refleje la posición relativa del scroll dentro del contenido del artículo.
- El indicador se actualiza en tiempo real mientras el usuario hace scroll (manual o programático).
- El indicador es visible solo cuando el contenido es más largo que el viewport (si todo el artículo cabe en pantalla, no hay nada que indicar).
- No se altera el comportamiento de lectura existente (marcar como leído, favoritos, abrir en navegador).

## Capabilities

### New Capabilities
- `reader-scroll-indicator`: indicador visual de progreso de scroll en la vista de detalle del artículo, que muestra en qué punto del documento se encuentra el usuario.

### Modified Capabilities
(ninguna — no existe spec previo para la pantalla de lectura que describa requisitos de scroll)

## Impact

- `lib/features/reader/presentation/screens/reader_screen.dart`: reemplazar el `SingleChildScrollView` simple por una versión instrumentada con `ScrollController` y un widget de indicador de progreso.
- Posible nuevo widget en `lib/features/reader/presentation/widgets/` (p.ej. `reading_progress_bar.dart`), ya que es específico del feature `reader` y no una abstracción de librería de terceros compartida.
- Sin cambios en `core/domain`, datasources, ni modelos de Hive.
- Sin cambios en rutas de navegación.
