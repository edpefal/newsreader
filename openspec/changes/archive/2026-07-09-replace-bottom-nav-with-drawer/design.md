## Context

La navegación actual usa `StatefulShellRoute.indexedStack` con un `_ScaffoldWithNavBar` que renderiza un `NavigationBar` en la parte inferior. Cada vez que se selecciona un tab, se dispara la recarga del cubit correspondiente (`loadFavorites`, `loadArchive`, `loadSources`).

El drawer reemplaza únicamente el widget de navegación; la estructura de rutas y el comportamiento del shell no cambian.

## Goals / Non-Goals

**Goals:**
- Reemplazar `NavigationBar` por `Drawer` en `_ScaffoldWithNavBar`.
- Mantener el badge de conteo de no leídos en Inbox.
- Mantener los disparadores de recarga de cubits al cambiar de sección.
- Preservar el estado de cada tab con `StatefulShellRoute.indexedStack`.

**Non-Goals:**
- Cambiar rutas, URLs o la estructura de navegación profunda.
- Modificar los AppBar individuales de cada feature.
- Agregar animaciones personalizadas al drawer.

## Decisions

**Mantener `StatefulShellRoute.indexedStack` sin cambios**

El drawer es solo la UI de navegación; la lógica de qué rama está activa sigue siendo responsabilidad del shell. Se sigue llamando `navigationShell.goBranch(index)` desde los taps del drawer, exactamente igual que con `onDestinationSelected` del `NavigationBar`.

**Usar `NavigationDrawer` (Material 3) en lugar de `Drawer` + `ListView`**

`NavigationDrawer` es el componente M3 equivalente a `NavigationBar` — soporta `selectedIndex`, `onDestinationSelected`, y `NavigationDrawerDestination`. La migración es semántica y simétrica: los mismos destinos, el mismo índice, solo cambia el contenedor.

**El AppBar recibe el ícono de hamburguesa automáticamente**

Cuando un `Scaffold` tiene un `drawer` definido, Flutter inserta automáticamente el `DrawerButton` (`≡`) en el `AppBar.leading` si no hay uno explícito. No se necesita modificar los AppBar de cada screen.

**Header del drawer**

Un `DrawerHeader` simple con el nombre de la app. Sin foto de perfil ni datos de usuario (fuera de scope).

## Risks / Trade-offs

- **Descubribilidad**: el drawer es menos visible que el bottom nav, especialmente en el primer uso. → Mitigación: en iOS y Android el gesto de deslizar desde el borde izquierdo es familiar. Aceptable para una app de lectura donde la navegación entre secciones no es frecuente.
- **Gesto conflictivo con swipe de inbox**: el swipe desde el borde izquierdo para abrir el drawer podría interferir con un futuro gesto de swipe derecha en artículos. Con el swipe actual (izquierda = marcar leído, solo `endToStart`) no hay conflicto. → Sin acción necesaria ahora.
