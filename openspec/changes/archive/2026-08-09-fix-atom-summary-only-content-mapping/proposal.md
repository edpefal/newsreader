## Why

Artículos de feeds Atom que solo publican `<summary type="html">` (sin `<content>`/`<content:encoded>`) — ej. `simonwillison.net/atom/everything/` — se muestran en el lector con las etiquetas HTML crudas como texto plano (`<p><strong><a href="...">...`). Verificado directamente corriendo `rss-parser` (la librería que usa `sync-feeds`) contra el feed real: para esos ítems, `item.content`, `item.contentEncoded` y `item.contentSnippet` son todos `undefined` — el único campo poblado es `item.summary`, que **ya viene HTML-unescapeado** por el parseo XML (es decir, contiene marcado real, no texto). El código actual de `sync-feeds/index.ts` solo usa `item.content`/`item.contentEncoded` para `content_html` (da `null` en este caso) y cae a `item.summary` como fallback de `excerpt` — así el HTML crudo termina en `excerpt`, que el cliente renderiza como texto plano (`Text(article.excerpt!)`), mostrando las etiquetas literales.

## What Changes

- `sync-feeds/index.ts`: `content_html` agrega `item.summary` como tercer fallback (`contentEncoded ?? content ?? summary ?? null`), ya que en items Atom sin `<content>` es el único HTML real disponible.
- `excerpt` deja de usar `item.summary` como fallback (queda `item.contentSnippet ?? null`) — `summary` ya se consume como `content_html` en ese caso, y nunca fue un texto plano apto para `excerpt`.
- Verificado que este fallback no afecta feeds RSS 2.0 (`item.summary` es `undefined` en ese formato según `rss-parser` — confirmado contra `stratechery.com/feed`), solo aplica al caso Atom sin `<content>`.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `feed-polling`: se agrega el mapeo correcto de `<summary type="html">` a `content_html` cuando un ítem Atom no trae `<content>`, y se corrige que `excerpt` ya no reciba HTML crudo sin strip.

## Impact

- `supabase/functions/sync-feeds/index.ts`: cambio de 2 líneas en el mapeo de campos (`content_html`, `excerpt`).
- No requiere migración de datos, pero tampoco se autocorrige solo: los artículos ya sincronizados con `excerpt` conteniendo HTML crudo quedan como están (dato histórico) — `sync-feeds` usa `ignoreDuplicates: true`, así que un re-sync no sobreescribe artículos existentes. El fix aplica a artículos genuinamente nuevos desde el deploy; para uno ya sincronizado, hace falta eliminar y re-agregar la fuente. Fuera de alcance de este change backfillear artículos existentes en limpio.
- No afecta al cliente Flutter — el fix es enteramente del lado del servidor.
