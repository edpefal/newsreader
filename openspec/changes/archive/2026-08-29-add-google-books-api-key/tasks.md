## 1. Conseguir la API key (acción externa del usuario)

- [x] 1.1 Crear (o elegir uno existente) un proyecto en Google Cloud Console: https://console.cloud.google.com/projectcreate — el usuario usó sus proyectos existentes "Reevo PROD" y "Reevo" (dev), uno por ambiente.
- [x] 1.2 Habilitar "Books API" en ese proyecto: https://console.cloud.google.com/apis/library/books.googleapis.com
- [x] 1.3 Crear una API key en "Credenciales" (https://console.cloud.google.com/apis/credentials) y restringirla a "Books API" únicamente (Application restrictions puede quedar sin restricción, ya que la llamada sale desde el servidor de Supabase, no desde el navegador/app del usuario).
- [x] 1.4 Guardar la key en un lugar seguro para el siguiente paso (no commitear en el repo).

## 2. Guardar la key como secret de Supabase

- [x] 2.1 `supabase secrets set GOOGLE_BOOKS_API_KEY=<key>` en `reevo` (prod, proyecto linkeado por defecto).
- [x] 2.2 `supabase secrets set GOOGLE_BOOKS_API_KEY=<key> --project-ref xgwnxhpdcrghrtdbrmpn` en `reevo-dev`.
- [x] 2.3 Confirmar con `supabase secrets list` (y `--project-ref xgwnxhpdcrghrtdbrmpn` para el segundo proyecto) que `GOOGLE_BOOKS_API_KEY` aparece en ambos.

## 3. Código

- [x] 3.1 En `supabase/functions/enrich-mentions/providers.ts`, modificar `resolveBookCover` para leer `Deno.env.get("GOOGLE_BOOKS_API_KEY")` y, si está presente, agregar `&key=<valor>` a la URL de Google Books; si no está presente, mantener la request sin key (comportamiento actual).
- [x] 3.2 Revisar `providers_test.ts`: los tests de libro usan `fakeFetch` con una función que ignora la URL exacta, así que no deberían romperse por el query param agregado — confirmar corriendo los tests.
- [x] 3.3 Correr `deno test` en `supabase/functions/enrich-mentions/` y confirmar que todos los tests pasan. 25/25 ok.

## 4. Deploy y verificación

- [x] 4.1 `supabase functions deploy enrich-mentions` (despliega a `reevo`, prod).
- [x] 4.2 `supabase functions deploy enrich-mentions --project-ref xgwnxhpdcrghrtdbrmpn` (despliega a `reevo-dev`) — confirmar con el usuario si aplica, igual que en `add-book-mention-amazon-link`.
- [x] 4.3 Sanity check manual con `curl` contra Google Books incluyendo la key (`https://www.googleapis.com/books/v1/volumes?q=Dune&maxResults=1&key=<key>`) para confirmar que ya no da 429 antes de dar el fix por bueno. Confirmado: 200 OK con resultados.
- [x] 4.4 Verificar manualmente en la app (el usuario) que una mención de libro conocido ahora muestra su portada real, no el ícono placeholder. Confirmado por el usuario.
