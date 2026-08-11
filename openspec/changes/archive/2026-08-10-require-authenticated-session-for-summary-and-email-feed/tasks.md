## 1. Cliente Flutter: mandar la sesión real

- [x] 1.1 `GeminiSummaryGenerator`: recibir `AuthClient` por constructor; si `currentAccessToken` es `null`, lanzar `SummaryGenerationException` con mensaje de sesión requerida sin llamar a `_httpClient.post`; si hay token, usarlo como `Authorization: Bearer <token>` en vez de `_supabaseAnonKey`. Quitar la constante `_supabaseAnonKey`.
- [x] 1.2 `SupabaseEmailFeedGenerator`: mismo cambio — recibir `AuthClient`, usar `currentAccessToken`, lanzar `EmailFeedGenerationException` si no hay sesión, quitar `_supabaseAnonKey`.
- [x] 1.3 `lib/core/di/injection.dart`: pasar `getIt<AuthClient>()` al construir `GeminiSummaryGenerator` y `SupabaseEmailFeedGenerator`.

## 2. Backend: rechazar sesiones no autenticadas

- [x] 2.1 `supabase/functions/summarize-articles/index.ts`: agregar el mismo bloque de validación que `delete-account`/`sync-feeds` (extraer token del header, `userClient.auth.getUser(token)`, 401 si falla) antes de armar el prompt o llamar a Gemini.
- [x] 2.2 `supabase/functions/create-feed/index.ts`: mismo bloque de validación antes de insertar en `generated_feeds`.

## 3. Tests

- [x] 3.1 Unit test de `GeminiSummaryGenerator`: sin `accessToken`, lanza `SummaryGenerationException` y no invoca `HttpClient.post`.
- [x] 3.2 Unit test de `GeminiSummaryGenerator`: con `accessToken`, el header `Authorization` usa ese token (no la anon key).
- [x] 3.3 Unit test de `SupabaseEmailFeedGenerator`: mismos dos casos (sin sesión falla sin llamar HTTP; con sesión manda el token real).
- [x] 3.4 Actualizar/revisar tests existentes de `generate_daily_summary_cubit`/`add_source_cubit` u otros que mockeen estos generators, si asumían la firma vieja del constructor. (No hace falta: mockean las interfaces `SummaryGenerator`/`EmailFeedGenerator`, no las clases concretas.)

## 4. Verificación

- [x] 4.1 Correr `flutter analyze` sin warnings.
- [x] 4.2 Correr `flutter test` y confirmar que toda la suite pasa.
- [x] 4.3 Desplegar ambas Edge Functions actualizadas (`supabase functions deploy summarize-articles create-feed` o vía MCP) y confirmar manualmente: una llamada con la anon key devuelve 401; una llamada real desde la app (usuario logueado) sigue funcionando.
