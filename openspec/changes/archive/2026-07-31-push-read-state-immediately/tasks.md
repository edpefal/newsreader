## 1. Helper compartido de mapeo

- [x] 1.1 Crear `lib/core/sync/article_state_row.dart` con una función pública que convierta un `ArticleModel` a la fila parcial de la tabla `articles` (`id`, `is_read`, `is_favorite`, `is_archived`, `read_at`, `saved_as_favorite_at`, `updated_at`, `deleted_at`), extrayendo la lógica hoy privada en `SyncUserData._articleStateToRow`.
- [x] 1.2 Actualizar `SyncUserData._syncArticles` para usar el helper compartido en vez de su método privado, y eliminar el método privado duplicado.

## 2. Push inmediato en `MarkArticleAsRead`

- [x] 2.1 Inyectar `CloudSyncClient` y `AuthClient` en `MarkArticleAsRead` (constructor).
- [x] 2.2 Tras `_repository.updateArticle(...)`, si `AuthClient.currentUserId != null`, disparar (sin `await` que bloquee el resto del método) un `CloudSyncClient.updatePartial('articles', [articleStateRow(articleActualizado)])` envuelto en `try/catch` que ignore `CloudSyncException` y cualquier otra excepción.
- [x] 2.3 Actualizar el registro en `lib/core/di/injection.dart` para pasar `CloudSyncClient` y `AuthClient` al construir `MarkArticleAsRead`.

## 3. Tests

- [x] 3.1 Test unitario de `MarkArticleAsRead`: al marcar leído con sesión activa, se llama `CloudSyncClient.updatePartial` con la fila esperada (mock de `CloudSyncClient` y `AuthClient` con `mocktail`).
- [x] 3.2 Test unitario: si `AuthClient.currentUserId` es `null`, no se llama `CloudSyncClient.updatePartial`.
- [x] 3.3 Test unitario: si `CloudSyncClient.updatePartial` lanza `CloudSyncException`, `MarkArticleAsRead.execute()` completa igual sin propagar el error.
- [x] 3.4 Test unitario del helper `article_state_row.dart` cubriendo el mapeo de campos (incluyendo `readAt`/`deletedAt` nulos).
- [x] 3.5 Verificar que los tests existentes de `SyncUserData` siguen pasando tras usar el helper compartido.

## 4. Verificación final

- [x] 4.1 Correr `flutter analyze` sin warnings.
- [x] 4.2 Correr `flutter test` completo.
- [x] 4.3 Prueba manual con dos sesiones/dispositivos: marcar leído en uno y confirmar en Supabase (tabla `articles`) que `is_read`/`updated_at` cambian sin necesidad de reabrir la app ni hacer pull-to-refresh.
