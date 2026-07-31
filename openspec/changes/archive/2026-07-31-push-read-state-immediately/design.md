## Context

`SyncUserData.execute()` sincroniza sources, articles y daily_summaries en batch, comparando `updatedAt` contra un cursor (`AppConstants.settingsLastSyncedAtKey`). Solo se dispara en momentos puntuales (login, resume, pull-to-refresh) — ver `openspec/specs/cloud-sync/spec.md`. `MarkArticleAsRead` (`lib/features/inbox/domain/usecases/mark_article_as_read.dart`) hoy solo actualiza Hive vía `ArticleRepository.updateArticle`, sin tocar la nube.

El mapeo `ArticleModel` → fila parcial de la tabla `articles` (`is_read`, `is_favorite`, `is_archived`, `read_at`, `saved_as_favorite_at`, `updated_at`, `deleted_at`) vive privado en `SyncUserData._articleStateToRow()`.

## Goals / Non-Goals

**Goals:**
- Reducir la ventana entre "el usuario marca leído" y "ese estado está en Supabase" de minutos/horas a segundos, sin esperar al próximo trigger de `SyncUserData`.
- Reusar `CloudSyncClient.updatePartial` (ya usado por `SyncUserData`) — no introducir un backend nuevo.
- Mantener `SyncUserData` como red de seguridad sin cambiar su contrato ni su comportamiento actual.

**Non-Goals:**
- No se generaliza a favoritos ni archivado en este change.
- No se implementa cola de reintentos ni persistencia de "pendiente de subir" más allá de lo que ya existe (`updatedAt` local).
- No se crea ningún Edge Function ni endpoint HTTP nuevo.
- No se cambia el esquema de Supabase ni las políticas RLS.

## Decisions

### 1. Push fire-and-forget dentro de `MarkArticleAsRead`, no en `InboxCubit`
`MarkArticleAsRead.execute()` dispara el push a la nube después de `updateArticle`, sin `await` sobre el resultado del push (el `await` solo cubre la escritura local). Así el use case queda como la única fuente de verdad de "qué pasa al marcar como leído" — `InboxCubit.markAsRead` no cambia.

Alternativa descartada: hacerlo en `InboxCubit`. Se descarta porque duplicaría la decisión de "leído implica push" en la capa de presentación, y cualquier otro llamador futuro de `MarkArticleAsRead` (p.ej. abrir un artículo desde Archivo) se quedaría sin el push.

### 2. Reusar `CloudSyncClient.updatePartial`, no `upsert` ni un método nuevo
`updatePartial` ya tiene la semántica correcta: actualiza por `id` si existe, no falla si no existe (no debería pasar para un artículo que el usuario ya tiene localmente, pero es más seguro que `upsert`, que requeriría columnas que el cliente no conoce como `source_id`).

### 3. Extraer el mapeo de fila a un helper compartido en `core/sync`
Se mueve `_articleStateToRow` de `SyncUserData` a una función pública (p.ej. `articleStateRow(ArticleModel m)`) en un archivo nuevo `lib/core/sync/article_state_row.dart`. Tanto `SyncUserData._syncArticles` como el nuevo push puntual en `MarkArticleAsRead` la llaman. Evita que dos lugares conozcan el nombre de las columnas de Postgres de forma independiente.

### 4. Gate por sesión con `AuthClient.currentUserId`
Antes de intentar el push, se chequea `AuthClient.currentUserId != null` — igual que `SyncUserData.execute()`. Si no hay sesión, no se intenta (evita una llamada de red que fallaría igual, y evita acoplar el use case a un estado de auth que no le corresponde manejar más allá de este chequeo).

### 5. Errores silenciados con try/catch sobre `CloudSyncException`
El push está envuelto en un `try/catch` que ignora `CloudSyncException` (y cualquier excepción de red). No se loggea como error de usuario ni se propaga — es exactamente el mismo criterio que ya aplica implícitamente hoy cuando `SyncUserData` falla parcialmente entre tablas.

## Risks / Trade-offs

- **[Riesgo] Un push inmediato exitoso pero el siguiente `SyncUserData` trae de vuelta una versión vieja del mismo artículo (remoto con `updated_at` menor)** → Mitigado: `SyncUserData._syncArticles` hace pull de `fetchChangedSince` usando el cursor, y el push inmediato ya dejó `updated_at` en el servidor más reciente que cualquier fila vieja: al ser last-write-wins por `updated_at`, no hay regresión real, pero vale confirmarlo en pruebas manuales con dos dispositivos.
- **[Riesgo] Doble escritura a la misma fila en Supabase si el usuario marca leído justo cuando corre un `SyncUserData` en paralelo** → Aceptado: ambas escrituras son idempotentes sobre el mismo estado final (`is_read=true`), no hay condición de carrera dañina, solo una escritura de más ocasional.
- **[Trade-off] Nueva dependencia de `MarkArticleAsRead` sobre `CloudSyncClient` y `AuthClient`** → Aceptado: son abstracciones de `core/`, no libs de terceros directas; ya es el patrón que sigue `SyncUserData`.

## Migration Plan

No aplica migración de datos ni de esquema. Cambio de código puro, retrocompatible: si el push falla o no hay sesión, el comportamiento observable es idéntico al actual (el sync por trigger sigue subiendo el cambio). Se puede desplegar sin coordinación con el backend.

## Open Questions

Ninguna pendiente — decisiones de alcance y manejo de errores ya cerradas en la fase de exploración previa.
