## Context

Ver `proposal.md` para la causa raíz, verificada corriendo `rss-parser@^3` localmente contra `simonwillison.net/atom/everything/` y `stratechery.com/feed`. Estado actual (`supabase/functions/sync-feeds/index.ts:116,126`):

```ts
const contentHtml = item.contentEncoded ?? item.content ?? null;
// ...
content_html: contentHtml,
excerpt: item.contentSnippet ?? item.summary ?? null,
```

`item.summary` es un campo que `rss-parser` solo popula para Atom (`undefined` en RSS 2.0, confirmado empíricamente). Cuando un ítem Atom no tiene `<content>`, `item.summary` contiene el único HTML disponible del ítem — ya decodificado de entidades XML por el parseo (`&lt;p&gt;` → `<p>`), es decir, HTML real, no texto plano.

## Goals / Non-Goals

**Goals:**
- Que el HTML de `<summary type="html">` se renderice como HTML cuando es el único contenido disponible, no se muestre como texto crudo.

**Non-Goals:**
- No se backfillean los artículos ya sincronizados con `excerpt` conteniendo HTML crudo (dato histórico). **Corregido tras verificación manual**: a diferencia de lo que se asumía originalmente acá, esto NO se autocorrige con un simple pull-to-refresh — `sync-feeds` hace `upsert(..., { onConflict: "source_id,article_url", ignoreDuplicates: true })`, así que un artículo ya existente nunca se sobreescribe en un re-sync. La única forma de forzar la recreación de un artículo puntual ya sincronizado es eliminar la fuente completa (cascadea el borrado de sus artículos) y volver a agregarla, o un borrado manual en Postgres — pero un `DELETE` directo tampoco alcanza por sí solo del lado del cliente, porque salta el mecanismo de soft-delete (`deleted_at`) que el cliente espera para purgar su copia local en Hive; sin ese borrado marcado, el artículo viejo queda cacheado localmente con su id original. Backfillear en limpio (ej. una migración que resincronice server-side, o instruir a los usuarios a eliminar y re-agregar fuentes afectadas) queda fuera de alcance de este change.
- No se distingue `<summary type="text">` de `<summary type="html">` — `rss-parser` no expone el atributo `type` como campo separado, y tratar cualquier `summary` disponible como HTML es consistente con cómo el resto del pipeline ya trata `content`/`contentEncoded` (sin verificar tipo tampoco).

## Decisions

### 1. `item.summary` como tercer fallback de `content_html`, no como fallback de `excerpt`

Es la lectura correcta del dato: cuando `rss-parser` solo pobló `summary`, ese es el contenido real del ítem (no un resumen aparte de un contenido más largo que no vino). Usarlo para `excerpt` (como hoy) pierde el contenido real del artículo y además lo muestra mal (crudo, sin renderizar). Usarlo para `content_html` lo muestra correctamente vía `FwhHtmlContentRenderer` en el cliente, sin ningún cambio del lado de la app.

**Alternativa considerada:** limpiar el HTML a texto plano (strip tags) antes de asignarlo a `excerpt`, preservando `content_html` como `null`. Se descarta: perdería los links y el formato del artículo (varios de estos posts de Simon Willison son casi enteramente una cita con links relevantes), y contradice el propósito de `content_html` — mostrar el artículo completo cuando el feed lo trae.

### 2. `excerpt` pierde el fallback a `item.summary`

Si no se saca, cualquier ítem Atom sin `<content>` termina con `content_html` y `excerpt` idénticos (el mismo HTML crudo en ambos campos) — redundante y siguen existiendo casos donde `excerpt` se muestra crudo en la UI de listas (que si acaso truncan visualmente `excerpt` como texto). Se prefiere que `excerpt` quede `null` en este caso (el cliente ya maneja bien `excerpt == null` en todas las listas) antes que mostrar HTML sin renderizar en ningún lugar.

## Risks / Trade-offs

- **[Riesgo] Algún feed Atom con `<summary type="text">` genuino (plain text) como único contenido** → Se trataría como HTML igual, sin gran impacto: texto plano sin `<`/`&` se renderiza igual en un widget HTML que en texto plano. El caso patológico (texto plano que casualmente contiene `<algo>`) es raro y de bajo impacto visual, no se justifica agregar detección de `type` para un edge case no observado.
- **[Trade-off] Artículos históricos con `excerpt` crudo no se corrigen retroactivamente** → Aceptado, ver Non-Goals — requiere eliminar y re-agregar la fuente afectada (o un borrado manual con soft-delete correcto) para forzar la recreación, no se corrige solo.
