## Why

`summarize-articles` (resumen diario con IA) y `create-feed` (generación de dirección de email) hoy solo exigen "algún JWT firmado por Supabase" (`verify_jwt = true`). La app llama a ambas con la **anon key pública**, que es un JWT válido (`role: "anon"`) y está embebida en el binario distribuido — cualquiera que la extraiga puede llamar a estas funciones sin loguearse, sin límite real (`create-feed` tiene un tope de 20/hora *global*, no por usuario). Esto ya era un riesgo aceptado cuando la app era de uso personal sin sistema de cuentas (ver comentario en `create-feed/index.ts`), pero la app ya tiene login obligatorio (Google/Apple vía Supabase Auth) y el resumen diario va a quedar detrás de un paywall — el gap deja de ser teórico: es la puerta de entrada para consumir cuota de Gemini (pronto de pago) gratis, sin pagar y sin loguearse.

Este change corrige el primer eslabón: exigir una sesión de usuario autenticada real (no la anon key) para ambas funciones. No implementa la verificación de pago (eso depende de la integración con Superwall, se aborda en un change separado).

## What Changes

- `GeminiSummaryGenerator` y `SupabaseEmailFeedGenerator` dejan de mandar la anon key hardcodeada como `Authorization`; usan el `accessToken` de la sesión activa (`AuthClient.currentAccessToken`), igual que ya hacen `DeleteAccount` y `SupabaseFeedSyncTrigger`. Si no hay sesión activa, la llamada falla del lado del cliente sin llegar a pegarle al backend.
- `summarize-articles` y `create-feed` (Edge Functions) decodifican el JWT recibido y **rechazan con 401** cualquier request cuyo `role` no sea `authenticated` (es decir, rechazan explícitamente la anon key, incluso aunque `verify_jwt = true` la deje pasar por ser un JWT válido).
- **BREAKING**: llamar a `summarize-articles` o `create-feed` con la anon key (sin sesión de usuario) deja de funcionar. No afecta a usuarios reales de la app (que siempre tienen sesión activa, login es obligatorio), solo cierra el acceso directo vía HTTP con la key pública.

## Capabilities

### New Capabilities

_(ninguna)_

### Modified Capabilities

- `daily-summaries`: el requirement "Generación de resumen diario del inbox" se amplía — la generación requiere una sesión de usuario autenticada real, no solo un JWT válido cualquiera.
- `email-to-rss-feeds`: el requirement "Generación de una dirección de email y feed RSS únicos" se amplía con el mismo requisito de autenticación real.

## Impact

- `lib/core/ai/gemini_summary_generator.dart` (recibe `AuthClient` por constructor)
- `lib/core/email_feed/supabase_email_feed_generator.dart` (recibe `AuthClient` por constructor)
- `supabase/functions/summarize-articles/index.ts`
- `supabase/functions/create-feed/index.ts`
- `lib/core/di/injection.dart` (inyectar `AuthClient` en ambos generators)
