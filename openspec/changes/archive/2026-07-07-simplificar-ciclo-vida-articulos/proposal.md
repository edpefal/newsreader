## Why

El comportamiento actual auto-archiva artículos no leídos después de 30 días y elimina artículos leídos después de 30 días, pero la pantalla "Leídos" filtra por `isArchived && !isRead` — lo que significa que los artículos que el usuario realmente lee nunca aparecen ahí, y los que nunca leyó sí aparecen. El usuario quiere un modelo simple: los artículos viven en el inbox hasta que los lee, y al leerlos pasan a "Leídos" permanentemente.

## What Changes

- Eliminar el auto-archivado de artículos no leídos > 30 días
- Eliminar la auto-eliminación de artículos leídos > 30 días
- Eliminar el use case `RunMaintenance` y su invocación en `main.dart`
- Corregir el query de "Leídos" para mostrar artículos con `isRead=true` (no `isArchived && !isRead`)
- Simplificar el query de Inbox a `!isRead` (eliminar el filtro `!isArchived`)
- Migrar artículos existentes con `isArchived=true` (eliminarlos, son residuos del comportamiento anterior)
- Cambiar el orden de "Leídos" de `publishedAt` a `readAt` descendente

## Capabilities

### New Capabilities

_(ninguna)_

### Modified Capabilities

- `article-lifecycle`: El ciclo de vida de un artículo cambia — ya no existe auto-archivado ni auto-eliminación. Un artículo solo se mueve cuando el usuario lo lee.

## Impact

- `lib/features/maintenance/` — use case `RunMaintenance` se elimina
- `lib/core/data/datasources/local/hive_article_datasource.dart` — queries `getArchive`, `getInboxArticles`, `getReadArticlesOlderThan`, `getUnreadNonArchivedArticlesOlderThan`
- `lib/core/domain/repositories/article_repository.dart` — métodos `getReadArticlesOlderThan`, `getUnreadNonArchivedArticlesOlderThan`
- `lib/core/data/repositories/article_repository_impl.dart` — implementación de los mismos
- `lib/main.dart` — eliminar invocación de `RunMaintenance`
- `lib/core/di/injection.dart` — eliminar registro de `RunMaintenance`
- Tests de maintenance y archive afectados
