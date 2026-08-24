## Why

Los ítems de las listas de la app (inbox, archivo, favoritos y fuentes) se ven demasiado juntos: no hay separación visual entre un artículo/fuente y el siguiente, lo que dificulta distinguir dónde termina un ítem y empieza otro al escanear la lista.

## What Changes

- Aumentar el espaciado vertical entre ítems consecutivos en las listas de artículos (inbox, archivo, favoritos), que comparten el widget `ArticleInboxTile`.
- Aumentar el espaciado vertical entre ítems consecutivos en la lista de fuentes (`_SourceTile` en `sources_screen.dart`).
- El espaciado debe mantenerse consistente entre las cuatro listas (mismo valor de separación).
- No se modifica el diseño interno de cada tile (thumbnail, título, subtítulo, trailing), solo el espacio entre tiles.

## Capabilities

### New Capabilities
- `list-item-spacing`: define el espaciado vertical mínimo entre ítems consecutivos en las listas de artículos y fuentes de la app.

### Modified Capabilities
(ninguna — no existe spec previa sobre densidad/espaciado de listas)

## Impact

- `lib/features/inbox/presentation/widgets/article_inbox_tile.dart` — tile compartido por inbox, archivo y favoritos.
- `lib/features/inbox/presentation/screens/inbox_screen.dart` — usa `AnimatedList` (sin `separatorBuilder`).
- `lib/features/archive/presentation/screens/archive_screen.dart` — usa `ListView.builder`.
- `lib/features/favorites/presentation/screens/favorites_screen.dart` — usa `ListView.builder`.
- `lib/features/sources/presentation/screens/sources_screen.dart` — tile `_SourceTile`, usa `ListView.builder`.
- `lib/features/sources/presentation/screens/source_detail_screen.dart` — mismo patrón `DateSeparator` + `ArticleInboxTile` que archivo/favoritos.
- Sin cambios de dominio, datos ni navegación. Cambio puramente visual/UI.
