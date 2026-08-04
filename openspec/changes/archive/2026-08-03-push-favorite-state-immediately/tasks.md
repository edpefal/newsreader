## 1. Cliente — `ToggleFavorite`

- [x] 1.1 En `lib/features/reader/domain/usecases/toggle_favorite.dart`, agregar dependencias `CloudSyncClient` y `AuthClient` al constructor, siguiendo exactamente el mismo patrón que `MarkArticleAsRead` (`lib/features/inbox/domain/usecases/mark_article_as_read.dart`).
- [x] 1.2 Después de `updateArticle`, disparar un push fire-and-forget (`unawaited`) a `CloudSyncClient.updatePartial('articles', [articleStateRow(...)])`, gateado por `AuthClient.currentUserId != null`, con el mismo manejo de errores silencioso (try/catch ignorando `CloudSyncException`/cualquier excepción de red).
- [x] 1.3 Actualizar `lib/core/di/injection.dart`: `ToggleFavorite` pasa a registrarse con las dependencias nuevas (`getIt(), getIt(), getIt()` en vez de `getIt()`).

## 2. Tests

- [x] 2.1 Crear `test/unit/features/reader/domain/usecases/toggle_favorite_test.dart` siguiendo el mismo esquema que `mark_article_as_read_test.dart`: marca/desmarca localmente, push inmediato con sesión activa (`is_favorite`/`saved_as_favorite_at` correctos), sin sesión activa no intenta push, push fallido no propaga error ni afecta la actualización local, y no espera la respuesta de red antes de completar `execute()` (fire-and-forget).

## 3. Verificación

- [x] 3.1 `flutter analyze` sin warnings nuevos.
- [x] 3.2 `flutter test` (unit) incluyendo los casos nuevos de `ToggleFavorite`. — 258/258 tests pasando.
- [x] 3.3 Probar manualmente: marcar un artículo como favorito en un dispositivo/sesión, y sin hacer pull-to-refresh, confirmar en Supabase (o en otro dispositivo) que `is_favorite=true` ya está reflejado. — Confirmado por el usuario: `is_favorite` quedó en `true` en Supabase sin pull-to-refresh.
