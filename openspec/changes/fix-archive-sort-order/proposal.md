## Why

La pantalla de Leídos muestra los artículos en orden ascendente (los más antiguos primero), mientras que el Inbox los muestra en orden descendente (los más recientes primero). Esta inconsistencia genera confusión: el usuario espera que todas las listas sigan el mismo orden cronológico.

## What Changes

- La lista de Leídos se ordena de más reciente a más antiguo, igual que el Inbox y Favoritos.
- Se corrige el criterio de ordenamiento en el use case `GetArchive` o en el datasource correspondiente.

## Capabilities

### New Capabilities

_(ninguna)_

### Modified Capabilities

- `article-lifecycle`: El requisito de ordenamiento de artículos leídos cambia — deben mostrarse de más reciente a más antiguo (mismo criterio que el resto de las listas).

## Impact

- `GetArchive` use case o la consulta a `ArticleLocalDataSource` que alimenta la pantalla de Leídos.
- `ArchiveScreen` no requiere cambios si el ordenamiento se corrige en la capa de datos/dominio.
