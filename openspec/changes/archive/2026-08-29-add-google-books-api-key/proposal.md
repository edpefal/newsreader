## Why

Google Books API cortó el acceso anónimo (sin API key): una consulta directa a `googleapis.com/books/v1/volumes` hoy devuelve `429 RESOURCE_EXHAUSTED` con `quota_limit_value: "0"`, confirmado con `curl` directo. `resolveBookCover` en `enrich-mentions/providers.ts` llama a Google Books sin ninguna key, así que **ninguna** portada de libro se resuelve más — no es un caso puntual de "libro sin match", es que la consulta falla siempre. Se descubrió al verificar manualmente el change `add-book-mention-amazon-link`.

## What Changes

- `resolveBookCover` pasa a incluir una API key de Google Cloud (Books API habilitada) en la query (`&key=<GOOGLE_BOOKS_API_KEY>`), leída de una variable de entorno/secret en vez de hacer la request anónima.
- La key se guarda como secret de Supabase (mismo mecanismo que `GEMINI_API_KEY` hoy) en ambos proyectos (`reevo` y `reevo-dev`), no hardcodeada en el código.
- Sin cambios de comportamiento observable a nivel de spec: el requirement de `article-mentions` ya documenta "Google Books para portada de libro, con fallback a placeholder si no hay match/falla" — este change solo restaura que ese camino vuelva a funcionar en la práctica. Por eso el change usa `skip_specs: true` (sin deltas de spec).
- No toca nada del link de Amazon (resuelto en `add-book-mention-amazon-link`, independiente de este fix) ni de podcast/música/artículo (no usan Google Books).

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

(ninguna — `skip_specs: true`, ver Why: es un fix de infraestructura que restaura comportamiento ya especificado, no cambia ningún requirement)

## Impact

- `supabase/functions/enrich-mentions/providers.ts`: función `resolveBookCover`.
- Nuevo secret de Supabase (`GOOGLE_BOOKS_API_KEY` o nombre similar) en `reevo` (`avyaxzhdilhufyimrzzb`) y `reevo-dev` (`xgwnxhpdcrghrtdbrmpn`).
- Requiere una acción externa del usuario: crear/usar un proyecto en Google Cloud Console, habilitar Books API, y generar la API key — no se puede automatizar completamente desde acá.
- `supabase/functions/enrich-mentions/providers_test.ts`: revisar si algún test de libro depende de la URL exacta sin el query param `key`.
