## Why

Inbox, Leídos y Favoritos ya no son bandejas efímeras: los artículos no leídos no expiran, los leídos quedan indefinidamente en "Leídos", y los favoritos son permanentes. Con fuentes ilimitadas y sync entre dispositivos, esas listas crecen sin límite, y hoy la única forma de encontrar un artículo puntual es hacer scroll manual. El PRD (sección 4.C) ya declara este requisito como pendiente de implementar.

## What Changes

- Cada una de las tres pantallas (Inbox, Leídos, Favoritos) gana un ícono de búsqueda en su `AppBar` que revela un campo de texto.
- El campo filtra, en memoria, la lista de artículos ya cargada en esa pantalla — no dispara ninguna consulta a Hive ni a Supabase.
- El match es case-insensitive, por substring, sobre tres campos: título del artículo, `sourceName` y `author`.
- No se busca sobre `contentHtml` ni `excerpt` (full-text queda fuera de alcance, ver PRD sección 8).
- No existe una pantalla de búsqueda global: cada pantalla busca únicamente dentro de su propia lista.
- Limpiar el campo de búsqueda restaura la lista completa sin necesidad de recargar desde el repositorio.

## Capabilities

### New Capabilities
- `article-search`: búsqueda local, por pantalla, sobre las listas de Inbox, Leídos y Favoritos, filtrando por título/fuente/autor sin consultar la capa de datos.

### Modified Capabilities
(ninguna — es una capability nueva que se apoya en el estado ya cargado por `InboxCubit`, `ArchiveCubit` y `FavoritesCubit`, sin cambiar los requisitos existentes de esas pantallas)

## Impact

- `lib/features/inbox/presentation/` (`InboxCubit`, `InboxState`, `InboxScreen`): agregar estado y UI de búsqueda.
- `lib/features/archive/presentation/` (`ArchiveCubit`, `ArchiveState`, `ArchiveScreen`): ídem.
- `lib/features/favorites/presentation/` (`FavoritesCubit`, `FavoritesState`, `FavoritesScreen`): ídem.
- Posible utilidad compartida en `core/utils/` para el matching de texto (mismo criterio de filtrado en las tres pantallas), evaluado en `design.md`.
- Sin cambios en `core/domain/`, `core/data/` ni en el backend/Supabase — la búsqueda opera enteramente sobre datos ya en memoria en el cliente.
- Tests nuevos: unit tests de cada cubit (filtrado) y ajustes a los widget tests existentes de las tres pantallas.
