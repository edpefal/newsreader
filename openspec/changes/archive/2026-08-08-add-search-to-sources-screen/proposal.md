## Why

La búsqueda local ya existe en Inbox, Favoritos y Leídos (capability `article-search`), pero la pantalla de Fuentes quedó afuera desde el inicio (`_searchableTabIndices = {0, 1, 2}` en `lib/presentation/app/router.dart`) — con una cuenta larga de fuentes, no hay forma de encontrar una en particular salvo scroll manual.

## What Changes

- Se agrega el ícono de búsqueda al tab "Fuentes", con el mismo mecanismo ya usado por los otros tres tabs (toggle en el AppBar compartido de `_ScaffoldWithNavBar`).
- La búsqueda filtra, en memoria, la lista de fuentes ya cargada — sin volver a consultar el repositorio local — por `name` o `author` de la fuente, insensible a mayúsculas/minúsculas y por coincidencia parcial.
- Sin coincidencias, se muestra el mismo estado `NoSearchResultsState` ya usado en Inbox/Favoritos/Leídos, distinto del estado vacío actual de "Aún no tienes newsletters".

## Capabilities

### New Capabilities

- `source-search`: búsqueda local por nombre o autor dentro de la lista de fuentes ya cargada en la pantalla de Fuentes. Se modela como capability propia (no una extensión de `article-search`) porque filtra un `NewsSource`, no un `Article` — campos y semántica de coincidencia distintos.

### Modified Capabilities

(ninguna — `article-search` queda intacta, esto no cambia su alcance)

## Impact

- `lib/presentation/app/router.dart`: agregar el índice 3 a `_searchableTabIndices`, y el caso `SourcesCubit.search(query)` en `_ScaffoldWithNavBarState._search()`.
- `lib/features/sources/presentation/cubit/sources_cubit.dart` / `sources_state.dart`: nuevo método `search(String query)`, `SourcesLoaded` gana `searchQuery` y `visibleSources` (mismo patrón que `FavoritesLoaded`/`FavoritesCubit.search`).
- Nuevo `lib/core/utils/source_text_matcher.dart` (o similar): función pura `sourceMatchesQuery(NewsSource, String query)`, análoga a `articleMatchesQuery` mirando `name` y `author`.
- `lib/features/sources/presentation/screens/sources_screen.dart`: usar `state.visibleSources` en vez de `state.sources`, mostrar `NoSearchResultsState` cuando la búsqueda no encuentra nada (distinto del `_EmptySourcesState` actual, que sigue aplicando solo cuando no hay ninguna fuente agregada).
- Tests nuevos/extendidos en `test/unit/features/sources/presentation/cubit/sources_cubit_test.dart`, `test/widget/features/sources/sources_screen_test.dart`, y test unitario para el matcher nuevo.
