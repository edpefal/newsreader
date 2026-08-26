## Why

La app hoy está diseñada mobile-first sin ningún breakpoint: en iPad usa el mismo `NavigationDrawer` modal, el mismo push de pantalla completa para artículos/fuentes/resúmenes, y el mismo ancho de texto sin límite que en un iPhone. El proyecto iOS ya declara soporte de iPad (`TARGETED_DEVICE_FAMILY = "1,2"`, orientaciones dedicadas en `Info.plist`), pero la UI desperdicia el espacio horizontal disponible y produce líneas de texto excesivamente largas en pantallas grandes, en contra de las mejores prácticas de Material 3 (breakpoints, `NavigationRail`) y Apple HIG (split view, ancho de lectura cómodo).

## What Changes

- Reemplazar el `NavigationDrawer` modal por un `NavigationRail` permanente en anchos ≥840dp (breakpoint "expanded" de Material 3); por debajo de 840dp se mantiene el Drawer modal actual sin cambios.
- El rail muestra las 5 destinations actuales (Inbox con badge de no leídos, Favoritos, Archivo, Fuentes, Resúmenes) más un ícono de Ajustes fijo al pie.
- **BREAKING (UX)**: "Cerrar sesión" deja de estar en el Drawer/rail y se muda dentro de la pantalla de Ajustes.
- Introducir un layout de master-detail (2 paneles: lista fija a la izquierda + panel derecho de detalle) para las 5 tabs en anchos ≥840dp, reemplazando el push de pantalla completa que usan hoy:
  - Inbox/Favoritos/Archivo: panel derecho muestra el lector del artículo seleccionado, o un placeholder si no hay selección.
  - Fuentes: panel derecho muestra el detalle de la fuente seleccionada; tocar un artículo de esa fuente reemplaza el panel derecho por el lector (con navegación apilada/botón volver dentro del panel, sin agregar una tercera columna).
  - Resúmenes: panel derecho muestra el detalle del resumen diario seleccionado.
  - Las rutas de detalle (`/article/:id`, `/sources/:id`, `/summaries/:date`) siguen siendo rutas reales de go_router (deep link y back button intactos); en modo split se renderizan dentro del panel derecho en lugar de reemplazar toda la pantalla.
  - Por debajo de 840dp, el comportamiento no cambia (push de pantalla completa).
- La selección actual se preserva simétricamente al cruzar el breakpoint de 840dp en cualquier dirección (rotación o resize de ventana), sin perder scroll/progreso de lectura; cada una de las 5 tabs recuerda su propia selección de forma independiente.
- Limitar el ancho del texto/HTML del artículo en el lector a un máximo fijo (~680pt), centrado, tanto en modo split como en pantalla completa (incluye iPhone en landscape).

## Capabilities

### New Capabilities
- `adaptive-navigation-rail`: comportamiento del `NavigationRail` permanente en anchos ≥840dp (destinations, badge, acceso a Ajustes) y su convivencia con el Drawer existente por debajo del breakpoint.
- `adaptive-master-detail`: layout de 2 paneles para las 5 tabs en anchos ≥840dp, incluyendo qué se muestra en el panel derecho por tab, navegación apilada dentro del panel, y persistencia/transición de la selección al cruzar el breakpoint o cambiar de tab.

### Modified Capabilities
- `navigation-drawer`: el `NavigationDrawer` y sus requisitos actuales (indicador de selección, badge de no leídos, header, separadores, íconos) quedan acotados a anchos <840dp; por encima del breakpoint no se usa el Drawer.
- `reader-typography`: se agrega un requisito de ancho máximo (~680pt) centrado para el texto/HTML del cuerpo del artículo, aplicable a cualquier ancho de pantalla.

## Impact

- `lib/presentation/app/router.dart`: reestructurar `StatefulShellRoute.indexedStack` y `_ScaffoldWithNavBar` para soportar `NavigationRail` + master-detail condicionados por ancho; las rutas de detalle (`/article/:id`, `/sources/:id`, `/summaries/:date`) pasan a poder renderizarse dentro de un panel en vez de solo a pantalla completa.
- Screens de lista: `inbox_screen.dart`, `favorites_screen.dart` (`features/favorites/presentation/screens/`), `archive_screen.dart`, `sources_screen.dart`, `summaries_screen.dart` — necesitan exponer/consumir un estado de "ítem seleccionado" por tab.
- Screens de detalle: `reader_screen.dart`, `source_detail_screen.dart`, `summary_detail_screen.dart` — deben poder embeberse dentro de un panel (sin asumir que son la pantalla completa) y soportar volver al padre dentro del mismo panel.
- `settings_screen.dart`: agrega la acción "Cerrar sesión" que hoy vive en el Drawer.
- Nuevo widget compartido en `core/widgets/` para el breakpoint/split (probablemente algo como `AdaptiveListDetailScaffold`), usado por las 5 tabs.
- No afecta a `core/data/`, `core/domain/` ni a la lógica de negocio (sync, favoritos, etc.) — es un cambio de presentación/navegación.
