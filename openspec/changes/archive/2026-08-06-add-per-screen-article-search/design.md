## Context

Inbox, Leídos y Favoritos son tres features independientes (`lib/features/inbox`, `lib/features/archive`, `lib/features/favorites`), cada uno con su propio Cubit/State/Screen, y CLAUDE.md prohíbe que un feature importe de otro. Los tres estados `*Loaded` (`InboxLoaded`, `ArchiveLoaded`, `FavoritesLoaded`) ya guardan `List<Article>` completa en memoria tras cargar desde el repositorio (ver `inbox_cubit.dart::_reload`). La búsqueda es puramente un filtro sobre esa lista ya cargada — no toca `core/domain/` ni `core/data/`.

## Goals / Non-Goals

**Goals:**
- Un único criterio de matching (case-insensitive, substring, sobre título/sourceName/author) aplicado igual en las tres pantallas.
- Cero llamadas nuevas a Hive/Supabase al escribir en el campo de búsqueda.
- Cambio aislado a la capa de `presentation` de cada feature; sin tocar `domain`/`data`.

**Non-Goals:**
- Búsqueda full-text sobre `contentHtml`/`excerpt` (excluido explícitamente en el proposal y en el PRD).
- Persistir el texto de búsqueda entre sesiones o entre pantallas.
- Debounce o resaltado (highlight) del texto coincidente — no forma parte del alcance actual, se puede agregar después sin romper este diseño.

## Decisions

- **Utilidad de matching compartida en `core/utils/article_text_matcher.dart`.** Las tres pantallas necesitan exactamente el mismo criterio (título/sourceName/author, case-insensitive, substring). Duplicarlo en tres cubits invita a que diverjan con el tiempo. `core/utils/` ya es el lugar designado para utilidades compartidas sin lógica de infraestructura (ver `IdGenerator`, `FeedContentChecker`), y no viola la regla de "un feature no importa de otro" porque no es específico de ningún feature. Alternativa descartada: un mixin de Cubit — más indirección para una función pura de una sola línea.
- **El query de búsqueda vive en el estado de cada Cubit (`searchQuery` en `InboxLoaded`/`ArchiveLoaded`/`FavoritesLoaded`), no en un Cubit/estado separado.** La lista filtrada se expone como getter derivado (`visibleArticles`) sobre `articles` + `searchQuery`, calculado en el propio estado (`Equatable` ya compara por valor). Alternativa descartada: mantener dos listas (`articles` y `filteredArticles`) en el estado — redundante y con riesgo de que queden desincronizadas.
- **El método de búsqueda del Cubit (`search(String query)`) solo re-emite el estado actual con el nuevo `searchQuery`, sin llamar a ningún use case.** Si el estado actual no es el `*Loaded` (ej. está en `*Loading`), la búsqueda no tiene efecto — no hay lista sobre la cual filtrar.
- **El ícono y el campo de búsqueda viven en el `AppBar` compartido (`_ScaffoldWithNavBar` en `router.dart`), no en el body de cada pantalla.** Decisión revisada dos veces durante la implementación: primero se extrajo un widget `ArticleSearchBar` a `core/widgets/` reusado por las tres pantallas (colocado en el body, ya que ninguna de las tres tenía `AppBar` propio — el título del tab vive en el shell compartido de navegación). Luego, a pedido explícito, se movió al `AppBar` real: como ese `AppBar` es único para los 5 tabs, `_ScaffoldWithNavBarState` (convertido de `StatelessWidget` a `StatefulWidget`) ahora decide si mostrar el ícono de búsqueda según `navigationShell.currentIndex` (solo para Inbox/Favoritos/Leídos, índices 0-2) y, al activarse, reemplaza el título del `AppBar` por un `TextField` cuyo `onChanged` se despacha al Cubit del tab activo (`InboxCubit`/`FavoritesCubit`/`ArchiveCubit`). El widget `ArticleSearchBar` quedó sin uso y se eliminó junto con su test; se conservó `NoSearchResultsState` (ahora en `core/widgets/no_search_results_state.dart`) porque cada pantalla sigue necesitando distinguir "sin resultados de búsqueda" de su estado vacío original. `ArchiveView` y `FavoritesView` volvieron a `StatelessWidget`; `InboxView` se mantiene `StatefulWidget` por las animaciones de la lista, sin relación con la búsqueda.
- **No se agregó un test de widget dedicado para la búsqueda en el `AppBar`.** `_ScaffoldWithNavBar` es una clase privada de `router.dart` que depende de `StatefulNavigationShell` (construido internamente por `go_router`, no instanciable directamente en un test) y de `getIt` para otras acciones del drawer; el repositorio no tiene tests existentes sobre `router.dart` por esta misma razón. Se verificó el comportamiento con `flutter analyze` + la suite completa en verde más prueba manual, consistente con el nivel de cobertura ya existente sobre el wiring de navegación.

## Risks / Trade-offs

- [Riesgo] Si la lista de una pantalla crece mucho (miles de artículos leídos acumulados), filtrar en cada tecleo podría notarse. → Mitigación: no hay debounce en esta versión por simplicidad; si se detecta jank real se puede agregar un `Timer` de debounce sin cambiar la spec (es un detalle de implementación, no de comportamiento observable).
- [Riesgo] Divergencia entre los tres Cubits si a futuro se agrega un campo nuevo de matching (ej. tags) en una pantalla y no en las otras. → Mitigación: al centralizar el criterio en `article_text_matcher.dart`, cualquier cambio de criterio se hace en un solo lugar y se refleja en las tres pantallas por construcción.
