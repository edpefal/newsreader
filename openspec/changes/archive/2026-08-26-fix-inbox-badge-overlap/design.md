## Context

El badge se construía con `Badge.count(count: count, child: Icon(...))` en dos `BlocBuilder<InboxCubit, InboxState>` (uno para `icon`, otro para `selectedIcon`) dentro del `NavigationDrawerDestination` de Inbox, en `lib/presentation/app/router.dart`. Un primer intento ajustó `alignment`/`offset` del `Badge.count` para desplazarlo fuera del ícono, pero el contenedor indicador de `NavigationDrawerDestination` es angosto y la caja del ícono chica, así que incluso con offset grande el badge seguía leyéndose "pegado" al ícono (confirmado con captura del simulador). Se descartó ese enfoque en favor de mover el badge fuera del ícono por completo, colocándolo junto al texto de la etiqueta ("Inbox"), que es el patrón común en apps como Gmail o Slack para contadores en listas de navegación.

## Goals / Non-Goals

**Goals:**
- Que el badge de conteo del Inbox se muestre a la derecha del texto "Inbox" en el `label` del destino, sin superponerse al ícono ni al texto, en ambos estados (seleccionado/no seleccionado) y con cualquier cantidad de dígitos ("1" a "999+").

**Non-Goals:**
- No se introduce un widget de badge reutilizable ni se refactoriza el resto del drawer; el ajuste queda acotado al destino Inbox.
- No se cambia la lógica de cálculo del conteo (`state.articles.length`) ni el umbral de truncado a "999+" (comportamiento propio de `Badge.count`).

## Decisions

- **Mover el badge del `icon`/`selectedIcon` al `label`, componiendo un `Row` con el texto "Inbox" + `SizedBox` de separación + `Badge.count(count: count)` sin `child`** (un badge "standalone" renderiza solo el pill de conteo). `icon`/`selectedIcon` vuelven a ser íconos simples sin `BlocBuilder`. Alternativa descartada: seguir ajustando `alignment`/`offset` sobre el ícono — requiere afinar valores mágicos por densidad de pantalla y sigue leyéndose apretado dado el tamaño reducido del contenedor de ícono en `NavigationDrawerDestination`.
- El `BlocBuilder<InboxCubit, InboxState>` se mueve del `icon`/`selectedIcon` al `label`, ya que solo ese slot necesita reaccionar al conteo ahora.

## Risks / Trade-offs

- [El `Row` dentro de `label` podría no tener suficiente ancho disponible en pantallas muy angostas, empujando el badge fuera de vista] → Verificar visualmente en el simulador con conteos de 1, 2 y 4+ dígitos antes de dar el cambio por terminado.
