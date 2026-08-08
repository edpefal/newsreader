## Context

Ver `proposal.md` para la motivación. Estado actual relevante:

- La búsqueda de Inbox/Favoritos/Leídos vive centralizada en `_ScaffoldWithNavBarState` (`lib/presentation/app/router.dart`) — un único `AppBar` compartido por los 5 tabs, con un `TextField` que reemplaza el título cuando `_isSearching` es `true`, y un `switch` sobre `navigationShell.currentIndex` que dispara `search(query)` en el cubit del tab activo. El ícono de búsqueda solo se muestra si `_searchableTabIndices.contains(currentIndex)`.
- `FavoritesCubit.search(query)` es el patrón más simple a replicar: re-emite el mismo estado `Loaded` con un campo `searchQuery` nuevo, y expone `visibleArticles` como getter derivado (`articles.where(articleMatchesQuery)`), sin tocar el repositorio.
- `articleMatchesQuery(Article, String)` (`lib/core/utils/article_text_matcher.dart`) es una función pura, sin estado, reusada por los tres cubits ya buscables.
- `SourcesLoaded` hoy solo tiene `sources` — no tiene `searchQuery` ni ningún concepto de filtro.

## Goals / Non-Goals

**Goals:**
- Paridad de UX exacta con Inbox/Favoritos/Leídos: mismo ícono, mismo comportamiento de toggle, mismo AppBar compartido — no una implementación paralela dentro de `SourcesScreen`.

**Non-Goals:**
- No se generaliza `article_text_matcher.dart` para aceptar tipos genéricos — se crea un matcher separado y pequeño para `NewsSource`, igual de simple que el existente, evitando abstraer prematuramente sobre dos casos.
- No se agrega búsqueda a "Resúmenes" (tab 4) — fuera de alcance, no lo pidió el usuario y no hay precedente de bloc/cubit con lista filtrable ahí todavía.

## Decisions

### 1. Capability nueva (`source-search`), no una extensión de `article-search`

`article-search` está scopeada explícitamente a listas de `Article` (Purpose: "dentro de una lista ya cargada (Inbox, Leídos o Favoritos)"), con requirements que hablan de campos de `Article` (`title`, `sourceName`, `author`, exclusión explícita de `contentHtml`/`excerpt`). Una fuente no tiene esos campos — mezclar ambas en una sola capability forzaría requirements genéricos poco claros o dos sub-secciones inconexas dentro del mismo documento. Mantenerlas separadas también sigue el patrón ya establecido en el repo de una capability por dominio (`source-management` separado de `article-lifecycle`, etc.).

### 2. Mismo patrón exacto que `FavoritesCubit`/`FavoritesLoaded`: `searchQuery` + getter derivado

No hay decisión real que tomar acá — es directamente copiar el patrón ya usado tres veces (`InboxLoaded`, `FavoritesLoaded`, `ArchiveLoaded` todos con esta misma forma), por consistencia y porque ya está probado que funciona bien con el AppBar compartido.

### 3. Matcher nuevo `sourceMatchesQuery`, sobre `name` y `author` únicamente

`NewsSource` no tiene un campo equivalente a `contentHtml`/`excerpt` que debería excluirse explícitamente — sus únicos campos de texto libre relevantes para búsqueda son `name` y `author` (`feedUrl` es una URL técnica, no útil para que el usuario busque por ella).

## Risks / Trade-offs

- **[Trade-off] Un cuarto `case` en el `switch` de `_ScaffoldWithNavBarState._search()`, un cuarto índice en `_searchableTabIndices`** → Aceptado: es el mismo patrón ya usado tres veces, agregar un cuarto caso no cambia la naturaleza del código ni amerita una refactorización a esta altura (ver Non-Goals — no se generaliza el matcher tampoco).
