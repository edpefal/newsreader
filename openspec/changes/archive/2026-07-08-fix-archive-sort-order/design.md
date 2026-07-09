## Context

La pantalla de Leídos (archive) muestra artículos con separadores de fecha calculados sobre `publishedAt`, pero el datasource los ordena por `readAt ?? publishedAt`. Esto genera una inconsistencia: un artículo publicado ayer y leído hoy queda al tope de la lista ordenada (readAt = hoy), pero su separador dice "ayer", haciendo que "ayer" aparezca antes de "hoy" en la pantalla.

El Inbox ordena por `publishedAt` DESC. Favoritos ordena por `savedAsFavoriteAt ?? publishedAt` DESC. El archivo es el único que usa `readAt`, creando la inconsistencia que reporta el usuario.

## Goals / Non-Goals

**Goals:**
- La lista de Leídos muestra los artículos de más reciente a más antiguo por fecha de publicación, igual que el Inbox.
- Los separadores de fecha coinciden con el orden de los artículos (sin grupos huérfanos ni invertidos).

**Non-Goals:**
- Cambiar el criterio de ordenamiento de Favoritos.
- Persistir o indexar `readAt` de una forma diferente.
- Modificar la UI de `ArchiveScreen`.

## Decisions

**Ordenar `getArchive` por `publishedAt` DESC en lugar de `readAt`**

La pantalla agrupa por `publishedAt` para los separadores. El único criterio de orden que garantiza coherencia entre el sort y los separadores es `publishedAt`. `readAt` tiene sentido semántico ("lo que leíste más recientemente"), pero rompe la agrupación visual. El cambio es de una línea en `HiveArticleDatasource.getArchive()`.

Alternativa descartada: ordenar el archive por `readAt` Y agrupar los separadores por `readAt`. Requeriría modificar `ArchiveScreen` y cambiaría la semántica de los separadores (ya no representarían la fecha de publicación, sino de lectura), lo cual es más confuso para el usuario.

## Risks / Trade-offs

- **Cambio de comportamiento para usuarios existentes**: artículos que antes aparecían al tope (por ser los más recientemente leídos) ahora pueden quedar más abajo si su `publishedAt` es antiguo. Es el comportamiento correcto y esperado, pero es un cambio visible. → Sin mitigación necesaria; es el fix deseado.
