## 1. Utilidad compartida de matching

- [x] 1.1 Crear `core/utils/article_text_matcher.dart` con una función pura que reciba un `Article` y un query string, y devuelva `true` si el título, `sourceName` o `author` contienen el query (case-insensitive, substring).
- [x] 1.2 Unit tests de la utilidad: coincidencia por título, por fuente, por autor, sin coincidencia, query vacío (debe matchear todo), y que `contentHtml`/`excerpt` no participen del match.

## 2. Inbox

- [x] 2.1 Agregar `searchQuery` a `InboxLoaded` y un getter `visibleArticles` que aplique `article_text_matcher` sobre `articles` cuando `searchQuery` no esté vacío.
- [x] 2.2 Agregar `InboxCubit.search(String query)` que re-emite el estado actual (si es `InboxLoaded`) con el nuevo `searchQuery`, sin llamar a ningún use case.
- [x] 2.3 Agregar ícono de búsqueda al `AppBar` de `InboxScreen` que revela un `TextField`; la lista debe leer `visibleArticles` en vez de `articles`.
- [x] 2.4 Unit tests de `InboxCubit`: buscar con resultados, buscar sin resultados, limpiar la búsqueda restaura la lista completa.
- [x] 2.5 Ajustar/agregar widget tests de `InboxScreen` cubriendo el flujo de búsqueda.

## 3. Leídos (Archive)

- [x] 3.1 Agregar `searchQuery` y `visibleArticles` a `ArchiveLoaded`, análogo a 2.1.
- [x] 3.2 Agregar `ArchiveCubit.search(String query)`, análogo a 2.2.
- [x] 3.3 Agregar UI de búsqueda a `ArchiveScreen`, análogo a 2.3.
- [x] 3.4 Unit tests de `ArchiveCubit` análogos a 2.4.
- [x] 3.5 Widget tests de `ArchiveScreen` análogos a 2.5.

## 4. Favoritos

- [x] 4.1 Agregar `searchQuery` y `visibleArticles` a `FavoritesLoaded`, análogo a 2.1.
- [x] 4.2 Agregar `FavoritesCubit.search(String query)`, análogo a 2.2.
- [x] 4.3 Agregar UI de búsqueda a `FavoritesScreen`, análogo a 2.3.
- [x] 4.4 Unit tests de `FavoritesCubit` análogos a 2.4.
- [x] 4.5 Widget tests de `FavoritesScreen` análogos a 2.5.

## 5. Mover el ícono de búsqueda al AppBar compartido

- [x] 5.1 Convertir `_ScaffoldWithNavBar` (`router.dart`) a `StatefulWidget`; el `AppBar` muestra el ícono de búsqueda solo en los tabs Inbox/Favoritos/Leídos (índices 0-2) y, al activarse, reemplaza el título por un `TextField` cuyo `onChanged` despacha al Cubit del tab activo.
- [x] 5.2 Quitar la UI de búsqueda del body de `InboxScreen`, `ArchiveScreen` y `FavoritesScreen`; eliminar el widget `ArticleSearchBar` (sin uso) y su test; mover `NoSearchResultsState` a `core/widgets/no_search_results_state.dart`.
- [x] 5.3 Quitar de los widget tests de las tres pantallas los casos que asumían el ícono/campo dentro del body (ya no aplican); mantener los casos de "sin resultados" basados en `searchQuery` del estado.
- [x] 5.4 Al cambiar de tab desde el drawer mientras se está buscando, cerrar la búsqueda (`_onDestinationSelected` llama a `_toggleSearch` si `_isSearching`).

## 6. Verificación final

- [x] 6.1 `flutter analyze` sin warnings nuevos.
- [x] 6.2 `flutter test` completo en verde.
- [x] 6.3 Prueba manual: buscar en cada una de las tres pantallas con datos reales/mock, confirmar que limpiar la búsqueda restaura la lista y que no hay llamadas de red al escribir.
