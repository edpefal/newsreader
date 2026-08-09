## 1. `sync-feeds`: mapeo de `content_html`/`excerpt`

- [x] 1.1 En `supabase/functions/sync-feeds/index.ts`, cambiar `const contentHtml = item.contentEncoded ?? item.content ?? null;` a `const contentHtml = item.contentEncoded ?? item.content ?? item.summary ?? null;`.
- [x] 1.2 Cambiar `excerpt: item.contentSnippet ?? item.summary ?? null,` a `excerpt: item.contentSnippet ?? null,`.

## 2. Verificación

- [x] 2.1 Verificar localmente con `deno run` contra `rss-parser`, reusando el XML real de `simonwillison.net/atom/everything/` y `stratechery.com/feed`, que el nuevo mapeo produce `content_html` correcto para el caso Atom-sin-`<content>` y no cambia el resultado para RSS 2.0 con `<content:encoded>`.
- [x] 2.2 Desplegar la función (`supabase functions deploy sync-feeds` o equivalente) y confirmar en la app real: pull-to-refresh sobre una fuente de Simon Willison's Weblog, abrir un artículo nuevo (sincronizado después del deploy) y confirmar que el HTML se renderiza correctamente, no como texto crudo. **Nota de verificación**: un simple pull-to-refresh no alcanzaba porque `sync-feeds` hace upsert con `ignoreDuplicates: true` — un artículo ya existente nunca se sobreescribe, y un `DELETE` directo en Postgres tampoco alcanza porque salta el mecanismo de soft-delete que el cliente espera para purgar su copia local (queda cacheada con el id viejo). La verificación real se logró borrando la fuente por completo (cascadea el borrado de sus artículos, capability `source-management`) y volviéndola a agregar — el resync completo confirmó que el HTML se renderiza correctamente.
