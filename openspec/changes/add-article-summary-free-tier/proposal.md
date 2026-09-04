## Why

`article-summaries` hoy requiere suscripción activa sin excepción, igual que `daily-summaries` antes de `add-daily-summary-free-tier` (ya archivado). A diferencia de ese caso, acá el free tier no necesita infraestructura nueva: el límite diario de `ai-usage-budget` (25/día) ya está parametrizado (`check_and_record_ai_usage(p_daily_limit)`), así que ofrecer 2 resúmenes de artículo gratis por día es cuestión de variar ese parámetro según haya o no suscripción activa, reusando la misma tabla `ai_usage_daily`.

## What Changes

- Generar un resumen de artículo ya no requiere suscripción activa de forma incondicional. Sin suscripción, el usuario puede generar hasta 2 resúmenes de artículo por día (día de servidor); con suscripción activa, sigue siendo hasta 25/día, sin cambios. Ambos casos comparten el mismo contador diario — no son cupos independientes que se suman.
- `ReaderScreen`: antes de abrir el bottom sheet de resumen, si no hay suscripción activa, se consulta el cupo diario restante; con cupo disponible se abre el sheet igual que hoy (sin paywall); sin cupo, se muestra el paywall de Superwall en vez de abrir el sheet. Con suscripción activa, comportamiento sin cambios.
- Al agotar el cupo (2/2 gratis o 25/25 con suscripción), el backend responde el mismo error ya existente (`ai_usage_limit_reached`) y el cliente muestra el mismo estado ya existente (`ArticleSummaryLimitReached`) — no hay estado nuevo. El copy de ese estado sí cambia: hoy tiene el número "25" hardcodeado en el string localizado (`articleSummaryLimitReachedTitle`), así que pasa a interpolar el límite vigente (25 o 2) en vez de un valor fijo.
- `enrich-mentions` deja de exigir suscripción activa: se elimina ese chequeo, quedando solo la exigencia de sesión autenticada (sin cambios). El enriquecimiento de menciones (portadas de libro/podcast/música, Open Graph de artículos mencionados) no invoca a Gemini ni descuenta ningún presupuesto, y el control de acceso real ya ocurrió en `summarize-article` — por lo tanto el free tier incluye enriquecimiento completo, sin degradar a menciones sin imagen.
- Localización: `articleSummaryLimitReachedTitle` (en/es/fr) pasa de texto fijo ("...tus 25 resúmenes...") a interpolar el límite vigente como placeholder ICU (`{limit}`), siguiendo la convención de claves parametrizadas ya usada en el proyecto (ver `summaryDetailTitle`). Se actualizan las 3 traducciones existentes, sin agregar claves nuevas.
- Fuera de alcance: no se agrega un indicador de cupo restante visible en `ReaderScreen` antes de tocar el botón (a diferencia de la pantalla de Resúmenes diarios), ni un mensaje inline de "cupo agotado" antes del paywall — acá se va directo al paywall.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `article-summaries`: la generación ya no requiere suscripción activa de forma incondicional; se agrega el camino de "cupo diario gratis disponible" (2/día) como alternativa válida antes de exigir paywall.
- `article-mentions`: el enriquecimiento de menciones ya no requiere suscripción activa; solo requiere sesión autenticada.
- `ai-usage-budget`: el límite diario de `article-summaries` pasa de ser un valor fijo (25) a depender de si el usuario tiene suscripción activa (25 con suscripción, 2 sin ella), sobre el mismo contador.

## Impact

- **Backend**: `supabase/functions/summarize-article/index.ts` (límite dinámico en vez de rechazo incondicional sin suscripción), `supabase/functions/enrich-mentions/index.ts` (eliminar chequeo de entitlement). Sin migraciones nuevas.
- **Cliente**: `core/constants/app_constants.dart` (nueva constante `aiUsageFreeTierDailyLimit`), `core/data/repositories/ai_usage_repository_impl.dart` (nueva dependencia de `SubscriptionStatusProvider` para resolver el límite vigente), `features/reader/presentation/screens/reader_screen.dart` (chequeo de cupo antes de abrir el bottom sheet, nueva dependencia de `AiUsageRepository`), el punto donde se construye `ReaderScreen` (ruta/DI), el widget que renderiza `ArticleSummaryLimitReached` (pasar el límite a interpolar), y `lib/l10n/app_en.arb`/`app_es.arb`/`app_fr.arb`.
