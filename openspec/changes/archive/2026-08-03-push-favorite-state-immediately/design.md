## Context

`ToggleFavorite` (`lib/features/reader/domain/usecases/toggle_favorite.dart`) hoy solo actualiza Hive vía `ArticleRepository.updateArticle` — el estado `isFavorite` solo llega a Supabase en el próximo `SyncUserData.execute()` (login, resume, pull-to-refresh). `MarkArticleAsRead` (`lib/features/inbox/domain/usecases/mark_article_as_read.dart`) ya resolvió exactamente este mismo problema para "leído" en el change `push-read-state-immediately`: push fire-and-forget a `CloudSyncClient.updatePartial` usando el helper compartido `articleStateRow` (`core/sync/article_state_row.dart`), gateado por `AuthClient.currentUserId`. Ver proposal.md - Why.

## Goals / Non-Goals

**Goals:**
- Reducir la ventana entre "el usuario marca/desmarca un favorito" y "ese estado está en Supabase" de minutos/horas a segundos, igual que ya pasa con "leído".
- Reusar exactamente el mismo mecanismo que `MarkArticleAsRead` (mismo helper, mismo gate, mismo manejo de errores) — no inventar un patrón nuevo para favoritos.

**Non-Goals:**
- No se generaliza a archivado en este change.
- No se implementa cola de reintentos ni persistencia de "pendiente de subir" más allá de lo que ya existe (`updatedAt` local).
- No se crea ningún Edge Function ni endpoint nuevo, ni se cambia el esquema de Supabase.

## Decisions

**Espejar `MarkArticleAsRead` al detalle, dentro de `ToggleFavorite`.** Después de `updateArticle`, se dispara un push fire-and-forget (`unawaited`) del mismo `articleStateRow` ya usado por `MarkArticleAsRead` y `SyncUserData`. No hace falta ninguna decisión de diseño nueva: es la misma forma, aplicada a otro caller. Se descartan las mismas alternativas que ya se descartaron en `push-read-state-immediately` (hacerlo en el Cubit/Bloc de presentación en vez del use case, usar `upsert` en vez de `updatePartial`) por las mismas razones documentadas en ese change.

**`ToggleFavorite` pasa a depender de `CloudSyncClient` y `AuthClient`,** igual que `MarkArticleAsRead`. Se actualiza el registro en `injection.dart` acorde.

**Sin helper nuevo.** `articleStateRow` ya incluye `is_favorite`/`saved_as_favorite_at` en su payload (fue diseñado para cubrir todo el estado de usuario del artículo, no solo lectura) — no hace falta tocarlo.

## Risks / Trade-offs

Los mismos riesgos ya evaluados y aceptados en `push-read-state-immediately` (last-write-wins por `updated_at` evita regresiones entre push inmediato y pull posterior; doble escritura ocasional si coincide con un `SyncUserData` en paralelo es inocua porque ambas escrituras son idempotentes sobre el mismo estado final) — aplican igual acá, sin novedad adicional al tratarse del mismo mecanismo sobre el mismo campo de estado del mismo artículo.

## Migration Plan

No aplica migración de datos ni de esquema. Cambio de código puro, retrocompatible: si el push falla o no hay sesión, el comportamiento observable es idéntico al actual (el sync por trigger sigue subiendo el cambio). Se puede desplegar sin coordinación con el backend.
