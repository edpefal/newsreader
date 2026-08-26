## Why

En iPad (layout de dos paneles, ≥840dp), tocar un artículo del Inbox en la columna central lo marca como leído al instante y lo hace desaparecer de esa lista, aunque siga abierto en el panel de detalle a la derecha. El usuario pierde de vista en qué artículo está parado dentro de la lista, y la lista "salta" (se re-acomoda) cada vez que abre algo. Se quiere que el artículo se mantenga visible mientras está abierto en el detalle, resaltado con un color de fondo distinto, y que solo pase a "Leídos" (desaparezca de la lista) cuando el usuario explícitamente lo cierra: tocando el botón de volver del lector, o seleccionando otro artículo.

## What Changes

- En el layout de dos paneles del Inbox, tocar un artículo ya no dispara inmediatamente el reload que lo saca de la lista central. En su lugar, la fila de ese artículo se resalta con un color de fondo (adecuado en light y dark theme) mientras permanece abierto en el panel de detalle.
- El artículo sigue marcándose `isRead=true` en el momento de abrirlo (comportamiento de datos sin cambios, vía `ReaderScreen`), pero su desaparición visual de la lista del Inbox se difiere hasta que deja de estar "abierto".
- Un artículo deja de estar "abierto" (y por lo tanto se anima su salida de la lista, igual que hoy) en dos casos:
  - El usuario toca el botón de volver (chevron) del lector, volviendo al estado vacío del panel derecho.
  - El usuario selecciona otro artículo de la columna central (el anterior se cierra y se anima su salida; el nuevo pasa a resaltarse).
- Cambiar de tab (Favoritos, Archivo, etc.) y volver al Inbox no cierra la selección: el artículo sigue resaltado y visible, según la regla ya vigente de persistencia de selección por tab.
- Este cambio aplica solo al layout expandido (≥840dp); en modo compacto (push a pantalla completa) el comportamiento actual no cambia.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `adaptive-master-detail`: agrega el requisito de que, en el panel central del Inbox, el artículo actualmente mostrado en el panel de detalle se resalte visualmente en la lista en vez de desaparecer, y que solo se archive de la lista al cerrarse explícitamente (volver o seleccionar otro).
- `article-lifecycle`: la regla "el artículo desaparece del inbox inmediatamente al abrirse" pasa a aplicar solo cuando no queda un panel de detalle mostrándolo (modo compacto, o modo expandido tras cerrar/reemplazar la selección); en el layout de dos paneles del Inbox, el artículo permanece visible (resaltado) mientras sigue siendo la selección abierta, aunque ya esté `isRead=true`.

## Impact

- `lib/features/inbox/presentation/screens/inbox_screen.dart`: el `onTap` en modo expandido deja de llamar a `cubit.markAsRead(...)`; pasa a comunicar la nueva selección al cubit sin sacar el artículo de la lista.
- `lib/features/inbox/presentation/cubit/inbox_cubit.dart` y `inbox_state.dart`: nuevo estado de "artículo abierto" (selección persistente para resaltar), distinto de la señal transitoria que ya dispara la animación de salida.
- `lib/features/inbox/presentation/widgets/article_inbox_tile.dart`: nuevo parámetro visual para el color de fondo resaltado cuando el artículo es la selección abierta.
- `lib/presentation/app/router.dart`: el builder de la raíz de la branch de Inbox en modo expandido (estado vacío del panel derecho) necesita notificar al cubit cuando ya no hay ningún artículo abierto (volver con el chevron).
- No afecta Favoritos ni Archivo (no tienen la acción de "marcar como leído" al abrir del mismo modo) ni el modo compacto.
