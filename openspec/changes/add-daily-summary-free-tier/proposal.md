## Why

`daily-summaries` hoy requiere suscripción activa sin excepción — no hay forma de que un usuario pruebe la feature antes de pagar. El proyecto de prod (`reevo`) tiene billing habilitado en la cuenta de Gemini asociada a `summarize-articles`, por lo que el límite de 20 requests/día del free tier de Gemini ya no es un techo duro ahí — el costo de dar acceso gratis limitado pasa a ser variable por generación, no un bloqueo de infraestructura. Eso habilita ofrecer 1 resumen diario gratis por semana como gancho de conversión, siguiendo el patrón ya usado por `article-summaries` (cupo server-enforced, cliente solo refleja el estado).

## What Changes

- El botón "Crear resumen" ya no exige suscripción activa de forma incondicional: un usuario sin suscripción puede generar como máximo 1 `DailySummary` exitoso por semana calendario (semana ISO, reset los lunes). Agotado ese cupo, se comporta como hoy (paywall de Superwall).
- Nuevo contador server-side por usuario para el cupo semanal gratis de `daily-summaries`, separado del contador diario de `ai-usage-budget` (que sigue siendo exclusivo de `article-summaries`). Mismo patrón de chequeo+incremento atómico y reset automático al cambiar de período.
- El backend de `summarize-articles` chequea, en este orden: suscripción activa (genera sin tocar el cupo gratis) → cupo semanal gratis disponible (genera y lo consume) → ninguno de los dos (rechaza, mismo error de "suscripción requerida" que hoy).
- Un fallo por falta de artículos (`NoArticlesTodayException`) o por resumen ya generado hoy (`DailySummaryAlreadyGeneratedException`) NO consume el cupo semanal gratis — el consumo solo se registra tras persistir un `DailySummary` exitosamente.
- Cliente: `AiUsageRepository`/`AiUsageStatus` se extiende con un segundo estado (semanal, propio de `daily-summaries`), reflejando lo último sincronizado desde el servidor. `SummariesCubit` expone ese estado en `SummariesLoaded` para mostrar, antes de generar, cuánto cupo gratis resta ("te queda 1 gratis esta semana"); si ya se agotó y no hay suscripción, un mensaje inline explica la situación ("ya usaste tu resumen gratis esta semana — vuelve el lunes o suscríbete") en vez de mostrar el paywall sin contexto.
- Localización: los textos nuevos (contador restante, mensaje de cupo agotado) se agregan con sus 3 traducciones (en/es/fr) en los `.arb`, bajo el prefijo `summaries*`.

## Capabilities

### New Capabilities
(ninguna — se modifica el comportamiento de capabilities existentes)

### Modified Capabilities
- `daily-summaries`: la generación ya no requiere suscripción activa de forma incondicional; se agrega el camino de "cupo gratis semanal disponible" como alternativa válida antes de exigir paywall, y las reglas de qué SHALL y SHALL NOT consumir ese cupo.
- `ai-usage-budget`: se agrega un segundo límite (semanal, por usuario, propio de `daily-summaries`) con su propio requirement de chequeo/incremento atómico, reset y consulta de estado — en paralelo al límite diario existente de `article-summaries`, sin modificarlo.

## Impact

- **Backend**: `supabase/functions/summarize-articles/index.ts` (chequeo de suscripción → cupo gratis → rechazo), nueva función/tabla de conteo semanal (equivalente a `check_and_record_ai_usage` pero por semana ISO y capability `daily-summaries`).
- **Cliente**: `core/domain/entities/ai_usage_status.dart`, `core/domain/repositories/ai_usage_repository.dart` y su implementación (nuevo estado semanal), `SummariesCubit`/`SummariesState`/`SummariesView` (lógica de decisión pre-paywall, contador, mensaje de cupo agotado), `lib/l10n/app_en.arb`, `app_es.arb`, `app_fr.arb`.
- Dos proyectos de Supabase (`reevo` prod, `reevo-dev` dev) — a confirmar con el usuario a cuál(es) desplegar la Edge Function actualizada antes de cerrar el change.
