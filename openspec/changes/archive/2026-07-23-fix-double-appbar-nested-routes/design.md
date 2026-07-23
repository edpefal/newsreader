## Context

`appRouter` (`lib/presentation/app/router.dart`) usa `StatefulShellRoute.indexedStack` con 5 branches (Inbox, Favoritos, Leídos, Fuentes, Resúmenes), envueltas por `_ScaffoldWithNavBar`: un `Scaffold` persistente con `AppBar(title: Text(_titles[currentIndex]))` y el `NavigationDrawer`.

`/article/:id` está declarada como `GoRoute` de nivel superior, **hermana** de `StatefulShellRoute`, no anidada dentro de ningún branch. Al navegar ahí, `_ScaffoldWithNavBar` queda completamente fuera del árbol de widgets — solo se ve el `Scaffold`/`AppBar` propio de `ReaderScreen` (back + título del artículo). Este es el comportamiento correcto y el que el usuario espera replicado en otras pantallas de detalle.

En cambio, 4 rutas de detalle/push están declaradas como sub-rutas dentro de sus branches (`/sources/:id`, `/sources/add`, `/sources/import-opml` dentro del branch `/sources`; `/summaries/:date` dentro del branch `/summaries`). Como siguen dentro del branch, `_ScaffoldWithNavBar` sigue en el árbol y su `AppBar` persistente queda visible por encima de la `AppBar` propia de cada pantalla — de ahí la doble barra.

## Goals / Non-Goals

**Goals:**
- Que las 4 rutas de detalle se comporten visualmente igual que `/article/:id`: sin la barra persistente del tab por encima.
- No cambiar ningún string de ruta ni ningún call site de navegación (`context.push(...)`).
- No tocar las pantallas de destino (`SourceDetailScreen`, `AddSourceScreen`, `ImportOpmlScreen`, `SummaryDetailScreen`) ni sus cubits — ya tienen su propio `Scaffold`/`AppBar` correcto.

**Non-Goals:**
- No se cambia el patrón de `StatefulShellRoute` en sí, ni el comportamiento de los 5 tabs raíz (`/`, `/favorites`, `/archive`, `/sources`, `/summaries`), que deben seguir preservando su estado (scroll, etc.) vía `IndexedStack` al cambiar de tab.
- No se toca `_ScaffoldWithNavBar` ni `_onDestinationSelected`.

## Decisions

### Mover las 4 rutas a nivel superior, replicando el patrón de `/article/:id`
Se declaran `/sources/:id`, `/sources/add`, `/sources/import-opml` y `/summaries/:date` como `GoRoute` de nivel superior (hermanas de `StatefulShellRoute`), con el mismo `path` string que ya tienen hoy. Como todos los `context.push(...)` existentes ya usan rutas absolutas (verificado: no hay ningún `context.push` con ruta relativa hacia estas pantallas), no hace falta tocar ningún call site — `go_router` resuelve por path absoluto sin importar dónde esté declarada la ruta en el árbol.

**Alternativa considerada**: quitar el `AppBar` propio de cada pantalla de detalle y en su lugar hacer que `_ScaffoldWithNavBar` cambie dinámicamente su `AppBar` (mostrar back+título de la pantalla activa en vez de hamburger+título del tab). Se descarta: acopla `_ScaffoldWithNavBar` al estado de navegación interno de cada branch (tendría que saber qué subpantalla está activa en cada uno de los 5 branches), mucho más invasivo que mover la declaración de la ruta, para el mismo resultado visual.

### Sin cambios en las pantallas de destino
Cada pantalla ya arma su propio `Scaffold`/`AppBar` correctamente (back automático + título). El bug es 100% de dónde cuelga la ruta en el árbol de `go_router`, no de cómo están armadas las pantallas.

## Risks / Trade-offs

- **[Riesgo] Mover `/sources/add` y `/sources/import-opml` a nivel superior podría romper la recarga de la lista de fuentes al volver** (`sources_screen.dart` usa `await context.push<bool>('/sources/add')` y recarga si `added == true`) → Mitigación: este patrón de "push top-level y esperar el resultado con `await`" es exactamente el mismo que ya usa `InboxScreen` con `/article/:id` (marca como leído al volver) — no depende de que la ruta esté anidada, solo de que `context.push` devuelva un `Future` con el resultado, lo cual sigue funcionando igual en una ruta de nivel superior.
- **[Riesgo] Perder la preservación de estado del tab "Fuentes"/"Resúmenes" al navegar a su detalle y volver** → Mitigación: no aplica, porque `IndexedStack` preserva el estado de los 5 branches raíz entre sí (al cambiar de tab), no el estado de las sub-rutas empujadas encima. Mover una ruta push (que de por sí no participa del `IndexedStack`) a nivel superior no cambia esto — es análogo a como `/article/:id` ya funciona hoy sin problema.
- **[Trade-off] Ninguno relevante** — es un cambio mecánico y acotado a la declaración de rutas.

## Migration Plan

Sin migración de datos ni cambios de contrato. Se reestructura `router.dart`, se verifica manualmente navegando a las 4 pantallas (y volviendo) en el emulador para confirmar que solo se ve una barra superior y que el comportamiento de recarga al volver sigue funcionando.
