## Why

El bottom navigation bar ocupa espacio permanente en la parte inferior de la pantalla y compite visualmente con el contenido de lectura. Un drawer lateral libera esa área, da más espacio vertical a las listas de artículos y escala mejor si en el futuro se agregan más secciones.

## What Changes

- El `NavigationBar` en la parte inferior es reemplazado por un `Drawer` (menú lateral deslizable desde la izquierda).
- Las cuatro secciones (Inbox, Favoritos, Leídos, Fuentes) pasan a ser entradas del drawer.
- El badge de conteo de artículos no leídos del Inbox se mantiene, ahora visible junto a la entrada del drawer.
- El `AppBar` de cada pantalla principal muestra el ícono de hamburguesa (`≡`) para abrir el drawer.
- La navegación entre secciones sigue usando `StatefulShellRoute.indexedStack` (preserva el estado de cada tab).

## Capabilities

### New Capabilities

_(ninguna)_

### Modified Capabilities

_(ninguna — este cambio es puramente de presentación; no altera requisitos de negocio ni comportamiento de las features)_

## Impact

- `lib/presentation/app/router.dart` — `_ScaffoldWithNavBar`: reemplazar `bottomNavigationBar` por `drawer`.
- Los `AppBar` de `InboxScreen`, `FavoritesScreen`, `ArchiveScreen` y `SourcesScreen` reciben automáticamente el ícono de hamburguesa al tener un `Drawer` en el `Scaffold` padre (go_router lo propaga a través del `navigationShell`).
- Sin cambios en use cases, cubits, repositorios ni rutas.
