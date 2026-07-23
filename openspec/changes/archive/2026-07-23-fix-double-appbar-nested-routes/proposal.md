## Why

Varias pantallas de detalle (fuente, agregar fuente, importar OPML, detalle de resumen) muestran dos barras superiores apiladas: la barra persistente del tab (hamburger + título del tab, ej. "Fuentes") y la barra propia de la pantalla (back + su título). Esto pasa porque esas rutas están anidadas dentro de un `StatefulShellBranch` del router, a diferencia de `/article/:id` (que sí se ve bien) por ser una ruta de nivel superior.

## What Changes

- Se mueven 4 rutas de detalle/push del router de estar anidadas dentro de sus `StatefulShellBranch` a ser rutas de nivel superior (hermanas del `StatefulShellRoute`), replicando el patrón ya usado por `/article/:id`:
  - `/sources/:id` (`SourceDetailScreen`)
  - `/sources/add` (`AddSourceScreen`)
  - `/sources/import-opml` (`ImportOpmlScreen`)
  - `/summaries/:date` (`SummaryDetailScreen`)
- Ningún string de ruta cambia (siguen siendo `/sources/:id`, `/sources/add`, etc.) — solo cambia dónde están declaradas en el árbol de rutas de `go_router`. Los call sites (`context.push('/sources/add')`, etc.) no requieren cambios porque ya usan rutas absolutas.
- Sin cambios visuales en las pantallas mismas (`SourceDetailScreen`, `AddSourceScreen`, `ImportOpmlScreen`, `SummaryDetailScreen` ya tienen su propio `Scaffold`/`AppBar` con back+título correctos) — el fix es puramente de qué las envuelve.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
(ninguna — es un bug de presentación/navegación, no un cambio de requirement de negocio; ningún spec existente documenta el comportamiento de las barras superiores)

## Impact

- `lib/presentation/app/router.dart`: se reestructura el árbol de rutas (mover 4 `GoRoute` de estar anidadas a nivel superior). Sin cambios en las pantallas ni en sus cubits.
- Sin cambios en `_ScaffoldWithNavBar`, en el modelo de datos, ni en ningún use case.
