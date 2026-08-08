## 1. Matcher: `sourceMatchesQuery`

- [x] 1.1 Crear `lib/core/utils/source_text_matcher.dart`: función pura `sourceMatchesQuery(NewsSource source, String query)`, análoga a `articleMatchesQuery` — coincidencia insensible a mayúsculas/minúsculas y por substring sobre `name` y `author`; `query` vacío o solo espacios matchea cualquier fuente.
- [x] 1.2 Crear `test/unit/core/utils/source_text_matcher_test.dart` (mismo formato que `article_text_matcher_test.dart`): coincidencia por nombre, por autor, sin coincidencias, query vacío matchea todo, insensibilidad a mayúsculas.

## 2. `SourcesCubit`/`SourcesState`: `search()`

- [x] 2.1 Agregar `searchQuery` (default `''`) a `SourcesLoaded` y un getter `visibleSources` derivado (`sources` filtrado por `sourceMatchesQuery` cuando `searchQuery` no está vacío), mismo patrón que `FavoritesLoaded.visibleArticles`.
- [x] 2.2 Agregar `SourcesCubit.search(String query)`: si el estado actual es `SourcesLoaded`, re-emite con el nuevo `searchQuery`, sin recargar desde el repositorio. Mismo patrón que `FavoritesCubit.search`.
- [x] 2.3 Actualizar `test/unit/features/sources/presentation/cubit/sources_cubit_test.dart`: tests para `search()` (filtra por nombre, filtra por autor, sin coincidencias, limpiar la búsqueda restaura la lista completa).

## 3. `SourcesScreen`: usar `visibleSources` + estado de sin resultados

- [x] 3.1 En `sources_screen.dart`, cambiar `(state as SourcesLoaded).sources` por `state.visibleSources`.
- [x] 3.2 Cuando `visibleSources` está vacío, mostrar `NoSearchResultsState` (ya existe en `lib/core/widgets/`) si `state.searchQuery` no está vacío; si no, seguir mostrando `_EmptySourcesState` como hoy.
- [x] 3.3 Actualizar `test/widget/features/sources/sources_screen_test.dart`: casos de lista filtrada por búsqueda, sin resultados de búsqueda (`NoSearchResultsState`) distinto del estado vacío por "sin fuentes".

## 4. Router: habilitar el tab "Fuentes" en el shell compartido

- [x] 4.1 En `lib/presentation/app/router.dart`, agregar el índice 3 a `_searchableTabIndices` y el caso `case 3: context.read<SourcesCubit>().search(query);` en `_ScaffoldWithNavBarState._search()`. (También se ajustó el hint del campo de búsqueda para el tab Fuentes — "Buscar por nombre o autor..." en vez del texto de artículos, que no aplica a fuentes.)

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` sin warnings nuevos.
- [x] 5.2 Correr `flutter test test/unit/core/utils/ test/unit/features/sources/ test/widget/features/sources/` y confirmar que todo pasa.
- [x] 5.3 Probar manualmente en la app: en el tab Fuentes, tocar el ícono de búsqueda, filtrar por nombre y por autor, confirmar que limpiar la búsqueda restaura la lista completa, y que cambiar de tab durante una búsqueda no la arrastra al otro tab.
