## Context

Ver `proposal.md` - Why. `resolveBookCover` (`supabase/functions/enrich-mentions/providers.ts`) hoy hace:

```ts
const url = `${GOOGLE_BOOKS_URL}?q=${encodeURIComponent(name)}&maxResults=1`;
```

sin ningún parámetro `key`. Google Books permite acceso anónimo a este endpoint bajo un cupo compartido global muy bajo (hoy en `0` según la respuesta 429 verificada), pensado para pruebas puntuales, no para tráfico de producción. Una API key de Google Cloud (gratis, requiere solo habilitar Books API en un proyecto) tiene su propio cupo por proyecto, independiente del anónimo.

## Goals / Non-Goals

**Goals:**
- Restaurar la resolución de portada de libro (`imageUrl`) a como se comportaba antes de que Google cortara el acceso anónimo.
- Guardar la API key como secret de Supabase, nunca hardcodeada en el repo.
- Que la ausencia de la key (ej. entorno local sin secrets configurados) degrade igual que hoy (`imageUrl` ausente), no que rompa la función.

**Non-Goals:**
- No se cambia el link de Amazon (`add-book-mention-amazon-link`, ya resuelto e independiente).
- No se agrega retry ni caching de las respuestas de Google Books — fuera de scope, el timeout/falla ya se maneja como "sin portada".
- No se restringe la key por dominio/IP más allá de restringirla a la Books API en Google Cloud Console (paso manual del usuario, no de código).

## Decisions

**Leer la key vía `Deno.env.get("GOOGLE_BOOKS_API_KEY")` dentro de `resolveBookCover`, agregarla a la query solo si está presente.**
Mismo patrón que otras Edge Functions del proyecto usan para secrets (ej. `GEMINI_API_KEY` en `summarize-article`). Si la variable no está seteada (por ejemplo, un entorno de desarrollo local sin `supabase secrets set` corrido), la función sigue haciendo la request sin `key` en vez de lanzar — se degrada al comportamiento anónimo actual (que hoy falla con 429, pero el código ya trata cualquier `!response.ok` como "sin portada", así que no hay una rama de código nueva que pueda romperse).

Alternativa considerada: hacer la key obligatoria y fallar el arranque de la función si falta. Se descartó — rompería la función entera (bloquearía también el link de Amazon y el resto de las menciones) por un problema que hoy sólo afecta la portada, contradiciendo el principio ya establecido en `article-mentions` de que una falla de proveedor nunca bloquea el resto.

**Nombre del secret: `GOOGLE_BOOKS_API_KEY`.**
Sigue la convención ya usada por `GEMINI_API_KEY`/`SUPERWALL_WEBHOOK_SECRET` en `supabase secrets list`.

**Restringir la key en Google Cloud Console a la Books API únicamente** (paso manual, no de código).
Reduce el impacto si la key se filtrara — solo serviría para consultar Books API, no otros servicios de Google Cloud.

## Risks / Trade-offs

- [El tier gratuito de Google Books API con key también tiene cupo diario, aunque mayor que el anónimo] → Si en el futuro se vuelve a agotar, el síntoma es el mismo de hoy (portada ausente, sin romper nada); se puede subir el cupo o migrar de proveedor sin cambiar el contrato de `enrichMention`.
- [Crear la key requiere que el usuario tenga o cree un proyecto de Google Cloud, con los pasos de habilitar facturación si Google lo exige para ese servicio] → Se guía paso a paso en tasks.md; es una acción externa que no se puede completar solo desde el código.
- [Dos secrets separados por proyecto de Supabase (`reevo`/`reevo-dev`)] → Puede usarse la misma API key de Google Cloud en ambos secrets (una sola key, sin necesidad de generar dos), ya que el cupo es por key/proyecto de Google Cloud, no por consumidor de Supabase.

## Migration Plan

- Sin cambios de esquema ni de datos persistidos.
- Deploy: requiere primero `supabase secrets set GOOGLE_BOOKS_API_KEY=<key>` en ambos proyectos (`reevo` y, si aplica, `reevo-dev` con `--project-ref xgwnxhpdcrghrtdbrmpn`), y luego `supabase functions deploy enrich-mentions` para que la función levante con la variable disponible.
- Rollback: quitar el secret (o revertir el código) y redeployar; sin la key, la función vuelve al comportamiento actual (sin portadas), no a un estado roto.
