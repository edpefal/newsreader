## 1. Backend

- [x] 1.1 En `supabase/functions/summarize-article/index.ts`, en el branch de `rawText` vacío, si `geminiData?.promptFeedback?.blockReason` existe, responder `{"error": "content_blocked"}` (status 502) en vez del mensaje genérico actual. Mantener el `console.error` existente con `promptFeedback` en ambos casos.
- [x] 1.2 En `supabase/functions/summarize-article/index.ts` y `supabase/functions/summarize-articles/index.ts`, cambiar el rechazo por falta de suscripción activa de `{"error": "Se requiere una suscripción activa"}` a `{"error": "subscription_required"}`.
- [x] 1.3 Confirmar con el usuario a qué proyecto(s) de Supabase desplegar. Confirmado: ambos.
- [x] 1.4 Desplegado `summarize-article` y `summarize-articles` a `reevo` (prod) y `reevo-dev`.

## 2. Cliente: nuevos AppErrorCode

- [x] 2.1 Agregar `AppErrorCode.contentBlocked` y `AppErrorCode.subscriptionRequired` en `lib/core/errors/app_error_code.dart`, con doc comments explicando cada caso.
- [x] 2.2 En `GeminiArticleSummaryGenerator.summarizeArticle`, agregar los chequeos de `decoded['error'] == 'content_blocked'` y `decoded['error'] == 'subscription_required'` (lanzando el `AppErrorCode` correspondiente) antes del fallback a `generationFailed`, en la misma cadena donde ya se chequea `ai_usage_limit_reached`.
- [x] 2.3 En `GeminiSummaryGenerator.summarize`, agregar solo el chequeo de `subscription_required`.
- [x] 2.4 Agregar los cases correspondientes en `lib/core/errors/app_error_code_localizations.dart`.

## 3. i18n

- [x] 3.1 Agregar las claves `errorContentBlocked` y `errorSubscriptionRequired` a `lib/l10n/app_en.arb` (template): la primera explica que ese artículo puntual no puede resumirse, sin invitar a reintentar; la segunda indica que se requiere una suscripción activa.
- [x] 3.2 Repetir en `lib/l10n/app_es.arb`, en español neutro con tuteo.
- [x] 3.3 Repetir en `lib/l10n/app_fr.arb` con contenido francés real (los errores de `AppErrorCode` ya tenían traducciones reales, no placeholders, en este archivo).
- [x] 3.4 Correr `flutter gen-l10n`.

## 4. Tests

- [x] 4.1 En `gemini_article_summary_generator_test.dart`, agregar casos donde el backend responde `{"error": "content_blocked"}` y `{"error": "subscription_required"}`, verificando que se lanza el `AppErrorCode` correspondiente sin llamar a `captureMessage` (son estados esperados, no bugs -- mismo criterio que `ai_usage_limit_reached`).
- [x] 4.2 En `gemini_summary_generator_test.dart`, agregar el caso de `{"error": "subscription_required"}`.

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` y `flutter test`. Ambos limpios (525 tests, incluido `neutral_spanish_test.dart`).
- [x] 5.2 Validado en producción: reintentando el mismo artículo bloqueado, el issue de Sentry **REEVO-PROD-3** ahora se titula "AppErrorCode.contentBlocked" (antes "AppErrorCode.generationFailed") -- confirma que el cliente distingue correctamente el bloqueo de contenido del error genérico.
- [x] 5.3 El caso `subscriptionRequired` ya se había observado en producción antes de este fix (REEVO-PROD-6, con el mensaje genérico viejo, antes del deploy) cuando la suscripción de sandbox del usuario expiró momentáneamente; la suscripción ya se renovó (`entitlements.is_active: true` confirmado en la base) así que no se pudo re-disparar el caso en vivo post-deploy, pero el mapeo está cubierto por los tests unitarios (tarea 4.1/4.2) y usa el mismo mecanismo ya validado para `content_blocked`.
