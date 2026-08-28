## Why

En modo compact (ancho angosto, ej. iPhone), al abrir un artículo/fuente/resumen se ve simultáneamente el `AppBar` principal de la app (logo, título de la tab, buscador) y el `AppBar` propio de la pantalla de detalle (back, título del ítem, acciones), en vez de que el detalle reemplace por completo la pantalla. Esto rompe la experiencia de "push de pantalla completa" que la capability `adaptive-master-detail` ya especifica para anchos menores a 840dp, y es una regresión introducida por el change `optimize-ipad-ux`: el `Scaffold` de `AdaptiveShell` sigue envolviendo `widget.navigationShell` (que incluye el `ReaderScreen` en compact) con su propio `appBar` y `drawer`, sin distinguir si la ruta activa es una lista o un detalle.

## What Changes

- `AdaptiveShell` deja de mostrar su `AppBar` (logo/título/buscador) y su `NavigationDrawer` cuando, en modo compact, la ruta actualmente activa dentro del `navigationShell` es una ruta de detalle (`/article/:id`, `/sources/:id`, `/summaries/:date`), dejando que el `Scaffold` propio de esa pantalla de detalle sea el único visible.
- El `AppBar`/drawer principal vuelve a mostrarse tan pronto el usuario navega de vuelta a la lista de la tab activa.
- El modo expanded (≥840dp, layout de dos paneles) no cambia: ahí el `AppBar` principal siempre convive con el panel de detalle, como ya especifica `adaptive-master-detail`.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `adaptive-master-detail`: aclara que, en modo compact, cuando el push de pantalla completa muestra una ruta de detalle, el chrome del shell principal (AppBar con logo/búsqueda y NavigationDrawer) no debe mostrarse simultáneamente con el AppBar propio del detalle.

## Impact

- `lib/presentation/app/adaptive_shell.dart`: `_AdaptiveShellState.build()` necesita conocer si la ruta activa dentro de `navigationShell` es una ruta de detalle en modo compact, para omitir `appBar`/`drawer` del `Scaffold` exterior en ese caso.
- `lib/presentation/app/router.dart`: puede necesitar exponer de forma accesible si la sub-ruta activa de la branch actual es una ruta de detalle (ej. vía `GoRouterState` / `context.watch<...>` o el `location` actual), sin romper `_adaptiveBranchShell` ni la lógica de `WindowSizeClass` ya existente.
- No afecta el modo expanded, ni las rutas direccionables (`/article/:id`, etc.), ni la persistencia de selección — sigue vigente lo definido en `adaptive-master-detail`.
