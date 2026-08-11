## Why

El resumen diario con IA va a ser la única feature paga de la app (el resto queda gratis). Hoy no existe ningún mecanismo de suscripción ni de verificación de pago: `summarize-articles` genera el resumen para cualquier sesión autenticada (una vez resuelto el change `require-authenticated-session-for-summary-and-email-feed`), sin chequear si esa cuenta pagó. Sin un chequeo server-side, un paywall puramente client-side es cosmético — cualquiera con la sesión logueada podría seguir llamando a la función directo y generar resúmenes gratis contra la cuenta paga de Gemini.

## What Changes

- Se integra el SDK de Superwall en la app, identificando a cada usuario con el mismo `user_id` de Supabase Auth (`Superwall.shared.identify(userId: <supabase user id>)` tras el login).
- El botón "Crear/Regenerar resumen de hoy" pasa a mostrar el paywall de Superwall cuando el usuario no tiene una suscripción activa, en vez de disparar la generación directamente.
- Nueva Edge Function `superwall-webhook`: recibe los eventos de Superwall (alta, renovación, cancelación, expiración de suscripción), valida la firma con el signing secret del endpoint, y mantiene sincronizada una tabla `entitlements` (`user_id`, `is_active`, `updated_at`) en la base de Supabase.
- `summarize-articles` consulta `entitlements` para el `user_id` autenticado antes de invocar a Gemini; si no está activo, responde con un error de suscripción requerida sin llamar a la API de IA.
- `create-feed` (email-to-RSS) **no cambia** — sigue siendo gratis, solo se paywallea el resumen diario.

## Capabilities

### New Capabilities
- `subscription-entitlements`: identificación del usuario ante Superwall, recepción y validación de sus webhooks, y la tabla de estado de suscripción que el resto del backend puede consultar.

### Modified Capabilities
- `daily-summaries`: el requirement "Generación de resumen diario del inbox" se amplía — generar un resumen requiere una suscripción activa, tanto en el gate de UI (paywall de Superwall) como en el backend (rechaza sin invocar a la API de IA si no hay entitlement activo).

## Impact

- `pubspec.yaml` (dependencia nueva: SDK de Superwall)
- `lib/core/subscription/` (nuevo: abstracción de estado de suscripción, implementación con Superwall — sigue la regla de abstracciones del proyecto, igual que `HttpClient`/`FeedParser`)
- `lib/features/summaries/presentation/screens/summaries_screen.dart` y su cubit (gate del botón de generar)
- `supabase/functions/superwall-webhook/` (nueva Edge Function)
- `supabase/functions/summarize-articles/index.ts` (chequeo de entitlement)
- Nueva migración: tabla `entitlements`
