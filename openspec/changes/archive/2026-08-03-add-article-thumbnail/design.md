## Context

Los artículos se crean exclusivamente en el servidor (`supabase/functions/sync-feeds/index.ts`, Deno + `rss-parser`), nunca en el cliente (ver capability `feed-polling`). El cliente solo hace pull de contenido ya creado, vía `sync_user_data.dart` → `ArticleModel` (Hive) → `Article` (entidad de dominio) → `ArticleInboxTile` (widget compartido por Inbox, Leídos, Favoritos y la pantalla de Fuente). `sourceIconUrl` ya recorre exactamente este mismo camino hoy y se renderiza con `CachedNetworkImageWidget` en `SourceIcon`; `imageUrl` sigue el mismo patrón. Ver proposal.md - Why / What Changes.

## Goals / Non-Goals

**Goals:**
- Extraer una imagen destacada por artículo del lado del servidor, con fallback entre varias fuentes del feed.
- Propagar esa imagen al cliente por el mismo mecanismo de pull ya usado para el resto del contenido.
- Mostrarla en `ArticleInboxTile` sin romper el layout de artículos sin imagen.

**Non-Goals:**
- No se re-procesan artículos ya sincronizados (sin backfill).
- No se optimiza, redimensiona ni proxyea la imagen — se usa la URL tal como viene del feed, igual que ya ocurre con `sourceIconUrl`.
- No se modifica `WebfeedFeedParser`/`FeedData`/`FeedItem` (cliente): no participan del flujo real de creación de artículos, solo de preview al agregar fuente/importar OPML.
- No se agrega manejo especial de feeds que solo son podcasts (iTunes) más allá de leer su imagen como una fuente más del fallback.

## Decisions

**Extracción vive en `sync-feeds`, no en el cliente.** Es el único lugar donde se crean artículos (decisión previa de `centralize-feed-fetching`); poner la extracción en el cliente requeriría duplicar lógica de parseo que ya fue deliberadamente centralizada.

**Orden de fallback: Media RSS → enclosure → iTunes → `<img>` en HTML.** Media RSS es el estándar más específico para "imagen destacada" y el más común en feeds de noticias ricos; enclosure es más genérico pero ampliamente soportado; iTunes suele aparecer en feeds de podcast/newsletter con imagen de portada, no necesariamente del artículo puntual, por eso va después; el `<img>` embebido es el fallback menos confiable (puede ser un ícono decorativo) pero es la única opción para feeds sin metadata de imagen explícita.

`rss-parser` (Deno) no expone Media RSS (`media:content`/`media:thumbnail`) por defecto — requiere declarar `customFields`, igual que ya se hizo para `content:encoded`. `enclosure` e `itunes.image` sí vienen soportados de fábrica.

**Extracción del `<img>` en HTML vía regex simple, no un parser de HTML completo.** Ya existe precedente de mantener el edge function liviano (sin dependencias pesadas); una regex que capture el primer `src="..."` de un tag `<img>` alcanza para el caso de fallback y evita sumar una dependencia de parseo de DOM en Deno solo para esto.

**Columna `image_url` nullable, sin default.** Mismo patrón que `source_icon_url`: nullable porque no todos los artículos van a tener imagen, y no tiene sentido inventar un valor por defecto.

**Sin backfill.** El upsert de `sync-feeds` usa `ignoreDuplicates: true` sobre `(source_id, article_url)`, así que un artículo ya existente nunca vuelve a evaluarse aunque el feed cambie. Cambiar esa estrategia para permitir backfill de imagen implicaría re-fetch masivo de feeds históricos y está fuera del alcance de este change (ver proposal.md).

**Thumbnail cuadrado a la derecha en `ArticleInboxTile`, reutilizando `CachedNetworkImageWidget`.** Mismo widget de infraestructura que ya usa `SourceIcon`, sin agregar una nueva abstracción de imagen. Cuando `imageUrl` es `null`, el `trailing` del `ListTile` se omite en vez de reservar espacio — así una lista mixta (algunos artículos con imagen, otros sin) no tiene huecos.

## Risks / Trade-offs

- **[Riesgo] El regex de `<img>` puede capturar una imagen irrelevante** (ícono, tracking pixel, imagen de un anuncio embebido) en feeds con HTML poco cuidado → Mitigación: es el último fallback, solo se usa cuando ninguna fuente de metadata explícita (Media RSS, enclosure, iTunes) está disponible; el costo de una imagen ocasionalmente incorrecta es bajo comparado con no mostrar nada.
- **[Riesgo] Imágenes rotas o muy pesadas de dominios de terceros** (el feed puede apuntar a una URL que ya no existe, o a una imagen enorme) → Mitigación: mismo riesgo que ya existe hoy con `sourceIconUrl`, ya mitigado por `CachedNetworkImageWidget` (maneja error/placeholder).
- **[Trade-off] Sin backfill significa que la funcionalidad se "siente" incompleta al lanzarla** (artículos viejos en el Inbox sin imagen mientras los nuevos sí la tienen) → Aceptado explícitamente en la conversación de exploración: evita la complejidad de un re-fetch masivo por ahora.

## Migration Plan

1. Migration de Postgres: agregar columna `image_url text null` a `articles`.
2. Deploy del edge function `sync-feeds` actualizado (extracción + insert de `image_url`).
3. Cambios de cliente (entidad, modelo Hive + `build_runner`, mapeo en `sync_user_data.dart`, UI) — no requieren coordinarse con el deploy del servidor: mientras `image_url` no exista en una fila remota, el cliente simplemente recibe `null` y la fila se muestra igual que hoy.
4. Rollback: si hay que revertir, alcanza con revertir el edge function (deja de poblar `image_url`) — no hace falta revertir la columna ni el cliente, que ya toleran `imageUrl == null`.
