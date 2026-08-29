## Why

Dos casos de fallo de generación de resumen, ambos determinísticos o al menos no resueltos por un reintento ciego, hoy caen en el mismo `AppErrorCode.generationFailed` genérico ("Algo salió mal. Intenta de nuevo."):

1. Gemini bloquea el prompt completo por su propio filtro de contenido (`promptFeedback.blockReason`, confirmado en producción como `PROHIBITED_CONTENT` para ciertos artículos de newsletters/Substack -- ver change archivado `surface-summary-backend-errors`). El bloqueo es determinístico para ese contenido: reintentar el mismo artículo nunca va a funcionar.
2. El backend rechaza por falta de suscripción activa (`hasActiveEntitlement` en `summarize-article`/`summarize-articles`) aunque la UI ya haya dejado pasar la solicitud -- confirmado en producción (REEVO-PROD-6): una suscripción de sandbox expiró entre el momento en que la UI verificó el entitlement local y el momento en que el backend lo verificó contra la tabla `entitlements`. El mensaje genérico no le dice al usuario que el motivo real es su suscripción.

## What Changes

- `summarize-article` (backend) detecta `promptFeedback?.blockReason` cuando Gemini no devuelve texto, y responde `{"error": "content_blocked"}` en vez del genérico actual.
- `summarize-article` y `summarize-articles` (backend) cambian el `error` del rechazo por falta de suscripción de la oración fija en español (`"Se requiere una suscripción activa"`, no machine-readable) a un código estable (`"subscription_required"`), igual que ya se hace con `"ai_usage_limit_reached"`.
- Nuevos `AppErrorCode.contentBlocked` y `AppErrorCode.subscriptionRequired` en el cliente, distinguidos del `generationFailed` genérico en `GeminiArticleSummaryGenerator` (ambos) y `GeminiSummaryGenerator` (solo `subscriptionRequired` -- el bloqueo de contenido no se investigó para el resumen diario, que agrupa varios artículos en un solo prompt).
- Mensaje propio para cada caso (en los 3 idiomas soportados): "no pudimos generar el resumen de este artículo" (sin invitar a reintentar la misma acción) para `contentBlocked`, y "necesitás una suscripción activa" para `subscriptionRequired`.

## Capabilities

### Modified Capabilities

- `article-summaries`: el escenario "Falla la generación" se separa en tres -- una falla genérica (sigue invitando a reintentar), una falla específica por bloqueo de contenido del proveedor de IA, y el rechazo del backend por falta de suscripción activa (ambas con mensaje propio, sin invitar a reintentar la misma acción sin cambios).
- `daily-summaries`: el escenario "Backend rechaza la generación sin suscripción activa" se actualiza para especificar que el sistema muestra un estado de error distinguible que indica específicamente el motivo de suscripción, en vez del error genérico de generación.

## Impact

- `supabase/functions/summarize-article/index.ts`, `supabase/functions/summarize-articles/index.ts`
- `lib/core/ai/gemini_article_summary_generator.dart`, `lib/core/ai/gemini_summary_generator.dart`
- `lib/core/errors/app_error_code.dart`, `lib/core/errors/app_error_code_localizations.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`, `lib/l10n/app_fr.arb`
- Tests de `gemini_article_summary_generator_test.dart` y `gemini_summary_generator_test.dart`
