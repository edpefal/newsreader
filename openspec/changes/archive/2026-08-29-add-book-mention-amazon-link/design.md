## Context

Ver `proposal.md` - Why. `resolveBook` en `supabase/functions/enrich-mentions/providers.ts` hoy hace un solo fetch a Google Books y deriva de ahí tanto `imageUrl` como `link` (`volumeInfo.infoLink ?? volumeInfo.previewLink`). Si Google Books no encuentra match, o encuentra un volumen sin esos dos campos, `link` queda `undefined` y `enrichMention` no le agrega ningún fallback (a diferencia de `type: "article"`, donde `link` siempre se setea a la URL original detectada).

## Goals / Non-Goals

**Goals:**
- Toda mención de tipo `book` termina con un `link` no vacío, siempre, independientemente del resultado de Google Books.
- La imagen de portada (`imageUrl`) se sigue intentando obtener de Google Books, sin cambios de comportamiento ahí.
- El cambio queda contenido en `resolveBook`/`enrichMention`; no toca el contrato de `podcast`/`music`/`article`.

**Non-Goals:**
- No se integra la API de Amazon Product Advertising (requiere cuenta de Associates aprobada y credenciales; el link de búsqueda no la necesita).
- No se localiza el dominio de Amazon por idioma/país de la app — siempre `amazon.com`.
- No se agrega tag de afiliado de Amazon Associates.
- No cambia nada en Flutter (`MentionCard`, `MentionEnricher`) — el contrato de wire (`EnrichedMention` con `link` string) no cambia de forma, solo la garantía de que para libros nunca es `null`.

## Decisions

**Separar la resolución de imagen y de link dentro de `resolveBook`.**
Hoy `resolveBook` devuelve `{ imageUrl?, link? }` como un solo resultado atado al mismo fetch. Se cambia a que el link se calcule siempre, de forma sincrónica, a partir de `name` (`buildAmazonSearchLink(name)`), y el fetch a Google Books se use solo para intentar completar `imageUrl`. Si el fetch falla o no hay match, `imageUrl` queda `undefined` pero `link` ya está calculado.

Alternativa considerada: mantener `resolveBook` con un único resultado y, en `enrichMention`, aplicar un fallback de Amazon solo cuando `result?.link` sea `undefined`. Se descartó porque el proposal pide reemplazo total (no fallback): incluso cuando Google Books sí trae `infoLink`, el link mostrado debe ser el de Amazon, no el de Google Books.

**Construcción del link: `https://www.amazon.com/s?k=<name>&i=stripbooks`.**
`k` es el término de búsqueda (el nombre del libro, `encodeURIComponent`), `i=stripbooks` restringe la búsqueda a la categoría de libros en papel/pasta blanda de Amazon (evita que el primer resultado sea un Kindle, audiolibro no relacionado, o un producto no-libro con nombre similar). No requiere API key ni cuenta de Associates: es un link de búsqueda público, igual que uno que un usuario armaría a mano en el navegador.

Alternativa considerada: Amazon Product Advertising API (PA-API) para buscar el ASIN exacto y linkear al producto puntual. Se descartó por proposal: requiere cuenta de Amazon Associates aprobada (con umbral de ventas para no perder acceso), credenciales AWS, y agrega una dependencia externa con aprobación fuera de nuestro control — desproporcionado para lo que resuelve (evitar redirigir a una página de búsqueda en vez de al producto exacto).

**Dominio fijo `amazon.com`, sin variar por locale de la app.**
Decisión explícita para no agregar una tabla de mapeo idioma/país → dominio de Amazon (`.com.mx`, `.es`, `.fr`, etc.) cuyo criterio de mapeo no está definido (la app soporta idiomas, no países) y cuyo beneficio es incierto (Amazon ya suele redirigir por IP).

## Risks / Trade-offs

- [El link de búsqueda no apunta al producto exacto, solo a resultados] → Aceptado explícitamente en el proposal; es preferible a no tener ningún link. El nombre de la mención (inferido por Gemini a partir del artículo) suele ser específico (título del libro), así que en la práctica el primer resultado de la búsqueda suele ser el libro correcto.
- [Actualizar `providers_test.ts`: el test "mención sin match se devuelve sin imageUrl ni link" (línea 61-73 hoy) asume el comportamiento viejo para libros] → Se reemplaza por un test que verifica que, sin match en Google Books, la mención de libro igual tiene el link de Amazon y `imageUrl` ausente.
- [Cambiar el comentario de cabecera de `enrichMention` en `providers.ts`, que hoy documenta "si el proveedor no encuentra match, se devuelve sin `imageUrl`/`link` (nunca `null` ni la descarta)" como regla general] → Hay que precisar que esa regla sigue aplicando tal cual a podcast/música, pero ya no a libro (que siempre tiene link).

## Migration Plan

- Cambio acotado a la Edge Function `enrich-mentions`. Sin cambios de esquema: `EnrichedMention` (`imageUrl`/`link`) ya se persiste hoy en Hive vía `article_summary_model.dart`, y el `link` de Amazon es del mismo tipo (`String?`), así que no requiere migración de TypeAdapter.
- **Dato ya persistido no se actualiza retroactivamente**: los resúmenes que un usuario ya generó antes de este cambio quedaron guardados en Hive con el `link` viejo de Google Books (o sin link, si no hubo match). Este cambio solo afecta las menciones de libros que se enriquecen a partir del deploy — no hay backfill de resúmenes existentes. Se considera aceptable: es el mismo comportamiento que cualquier cambio en un proveedor de enriquecimiento (ej. si Google Books cambiara su formato de respuesta mañana, tampoco se reprocesarían resúmenes viejos).
- Deploy: `supabase functions deploy enrich-mentions` despliega a `reevo` (prod, proyecto linkeado por defecto). Confirmar con el usuario si también se debe desplegar a `reevo-dev` (`--project-ref xgwnxhpdcrghrtdbrmpn`) antes de dar el change por terminado, según CLAUDE.md.
- Rollback: revertir el commit y volver a desplegar la función; no hay cambios de esquema ni de datos persistidos que revertir.
