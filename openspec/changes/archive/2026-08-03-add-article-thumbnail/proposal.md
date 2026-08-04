## Why

Los lectores de feeds comparables (Reeder, Feedly) muestran una imagen destacada junto a cada artículo cuando el feed la provee; hoy el Inbox (y Archive/Favorites/Fuente) solo muestran texto, aunque muchos feeds ya traen imagen en `media:content`, `enclosure` o embebida en el HTML del artículo. Agregarla mejora el escaneo visual de la lista sin requerir ningún cambio de comportamiento en la sincronización existente.

## What Changes

- El servidor (`sync-feeds` Edge Function) extrae una URL de imagen destacada de cada ítem del feed, probando en orden: `media:content`/`media:thumbnail` → `enclosure` (`type` `image/*`) → `itunes:image` → primer `<img>` dentro de `content_html`. Si ninguna fuente produce una imagen, el artículo se guarda sin imagen (no es un error).
- Nueva columna `image_url` (nullable) en la tabla `articles` de Supabase.
- El pull de sincronización del cliente (`sync_user_data.dart`) trae `image_url` igual que el resto del contenido del artículo (pull-only, mismo patrón que `content_html`/`excerpt`).
- Nuevo campo `imageUrl` en `Article`, `ArticleModel` (con su `HiveField` y regeneración de `.g.dart`).
- `ArticleInboxTile` (compartido por Inbox, Archive, Favorites y Fuente) muestra un thumbnail cuadrado a la derecha del texto cuando `imageUrl` no es nulo; cuando es nulo, la fila se ve igual que hoy (sin espacio reservado).
- Sin backfill: artículos ya sincronizados antes del deploy no obtienen imagen retroactivamente (el upsert de `sync-feeds` usa `ignoreDuplicates` sobre `source_id,article_url`, así que no se re-procesan).

## Capabilities

### New Capabilities
- `article-thumbnails`: extracción server-side de la imagen destacada de un ítem de feed, y su presentación como thumbnail en las listas de artículos.

### Modified Capabilities
- `feed-polling`: el fetch de cada ítem de feed ahora también intenta obtener una imagen destacada, con fallback entre varias fuentes del feed; la ausencia de imagen no es una condición de fallo.

## Impact

- **Servidor**: `supabase/functions/sync-feeds/index.ts` (lógica de extracción), nueva migration en `supabase/migrations` (columna `image_url`).
- **Cliente — datos**: `core/domain/entities/article.dart`, `core/data/models/article_model.dart` (+ `.g.dart` regenerado vía `build_runner`), `features/sync/domain/usecases/sync_user_data.dart` (`_articleFromRow`).
- **Cliente — UI**: `features/inbox/presentation/widgets/article_inbox_tile.dart` (usa `CachedNetworkImageWidget`, mismo patrón que `SourceIcon`). Afecta a Inbox, Archive, Favorites y Fuente por ser un widget compartido.
- **No afectado**: `WebfeedFeedParser`/`FeedData`/`FeedItem` (solo se usan para preview al agregar fuente/importar OPML, no participan del flujo real de creación de artículos) — fuera de alcance de este change.
