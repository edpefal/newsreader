## Why

En el drawer de navegación, el badge de conteo de artículos no leídos del destino "Inbox" se superpone visualmente encima del ícono en vez de ubicarse en su esquina, dificultando la lectura tanto del ícono como del número. Se ve en capturas reales del simulador con conteos altos (ej. "999+").

## What Changes

- Ajustar el posicionamiento del `Badge.count` que envuelve los íconos `Icons.inbox_outlined` / `Icons.inbox` en `NavigationDrawerDestination` (`lib/presentation/app/router.dart`) para que el badge quede desplazado a la esquina superior derecha del ícono, sin superponerse ni taparlo, tanto en el estado seleccionado como no seleccionado.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `navigation-drawer`: el requirement de "Contador de no leídos legible con números grandes" se amplía para exigir que el badge no se superponga visualmente sobre el ícono del destino Inbox, en cualquier estado de conteo (uno, dos o tres+ dígitos) y en ambos estados de selección.

## Impact

- `lib/presentation/app/router.dart`: los dos `BlocBuilder<InboxCubit, InboxState>` que construyen `icon` y `selectedIcon` del destino Inbox.
- Sin cambios de datos, API ni dependencias nuevas; es un ajuste puramente visual sobre un widget `Badge` ya existente de Material 3.
