## 1. Backend — `summarize-article`

- [x] 1.1 Calcular `isSubscribed` (mismo `hasActiveEntitlement(entitlementRow)` que ya se lee) y reemplazar el rechazo incondicional `if (!hasActiveEntitlement) return subscription_required` por: si `!isSubscribed`, seguir (no rechazar todavía).
- [x] 1.2 Definir `AI_FREE_TIER_DAILY_LIMIT = 2` junto a `AI_DAILY_SUMMARY_LIMIT = 25`, y pasar `isSubscribed ? AI_DAILY_SUMMARY_LIMIT : AI_FREE_TIER_DAILY_LIMIT` como `p_daily_limit` a `check_and_record_ai_usage`.
- [x] 1.3 Si `!isSubscribed` y el chequeo de `check_and_record_ai_usage` rechaza (cupo gratis de 2 agotado), responder con el mismo error usado para "sin suscripción ni cupo" (`subscription_required`, mismo código que hoy usa el rechazo incondicional) -- no inventar un código nuevo.
- [x] 1.4 Confirmar que el rechazo por límite alcanzado con suscripción activa (`ai_usage_limit_reached`, ya existente) sigue funcionando sin cambios.
- [x] 1.5 Se extrajo `resolveDailyLimit(isSubscribed)` (+ `AI_DAILY_SUMMARY_LIMIT`/`AI_FREE_TIER_DAILY_LIMIT`) a `usage_limit.ts`, mismo patrón que `entitlement.ts`, con `usage_limit_test.ts` cubriendo ambos casos.

## 2. Backend — `enrich-mentions`

- [x] 2.1 Eliminar el bloque que lee `entitlements` y responde 403 "Se requiere una suscripción activa" -- dejar solo el chequeo de sesión autenticada (token válido) que ya existe antes de ese bloque.
- [x] 2.2 Sin código muerto: se borró `entitlement.ts`/`entitlement_test.ts` de `enrich-mentions` (ya sin ningún uso en la función, era una copia intencional por-función, no compartida).

## 3. Cliente — límite dinámico

- [x] 3.1 `AppConstants`: agregar `aiUsageFreeTierDailyLimit = 2`, junto a `aiUsageDailySummaryLimit = 25` existente.
- [x] 3.2 `AiUsageRepositoryImpl`: agregar dependencia `SubscriptionStatusProvider`; en `getStatus()`, resolver `dailyLimit` como `_subscriptionStatusProvider.isSubscribed ? AppConstants.aiUsageDailySummaryLimit : AppConstants.aiUsageFreeTierDailyLimit` en vez de la constante fija actual.
- [x] 3.3 Actualizar el registro de `AiUsageRepositoryImpl` en `core/di/injection.dart` con la nueva dependencia.

## 4. Cliente — gate en ReaderScreen

- [x] 4.1 Inyectar `AiUsageRepository` en `ReaderScreen` (constructor + donde se construye en la ruta/DI correspondiente).
- [x] 4.2 `_onSummaryPressed()`: cuando `!isSubscribed`, antes de mostrar el paywall, consultar `AiUsageRepository.getStatus()`; si `!limitReached` (hay cupo), llamar a `_openSummarySheet(context)` directo, igual que con suscripción activa; si `limitReached`, mostrar el paywall como hoy.
- [x] 4.3 Con suscripción activa, comportamiento sin cambios (abre el sheet directo).

## 5. Cliente — copy del límite alcanzado, dinámico

- [x] 5.1 `ArticleSummaryState`/`ArticleSummaryLimitReached`: agregar campo `dailyLimit: int` al estado (además del `remainingToday: 0` que ya tiene), para que el widget sepa si interpolar "2" o "25".
- [x] 5.2 `ArticleSummaryCubit`: donde hoy se emite `const ArticleSummaryLimitReached()` al capturar `AppErrorCode.aiUsageLimitReached`, cambiar a consultar el `AiUsageStatus` completo (no solo `remaining`) y emitir `ArticleSummaryLimitReached(dailyLimit: status.dailyLimit)`.
- [x] 5.3 `lib/l10n/app_en.arb`/`app_es.arb`/`app_fr.arb`: convertir `articleSummaryLimitReachedTitle` de texto fijo a clave ICU parametrizada con placeholder `{limit}` (tipo `int`, mismo patrón que `summaryDetailTitle`), actualizando las 3 traducciones para que el número salga de la interpolación, no hardcodeado en el string.
- [x] 5.4 `article_summary_bottom_sheet.dart`: pasar `state.dailyLimit` (o el valor correspondiente) al llamar a `l10n.articleSummaryLimitReachedTitle(...)`.
- [x] 5.5 Correr `flutter gen-l10n` tras el cambio de `.arb`.

## 6. Tests

- [x] 6.1 `test/unit/core/data/repositories/ai_usage_repository_impl_test.dart` -- casos: sin suscripción devuelve `dailyLimit=2`; con suscripción devuelve `dailyLimit=25`.
- [x] 6.2 `test/widget/features/reader/reader_screen_test.dart` -- casos: sin suscripción y con cupo → abre el sheet sin paywall; sin suscripción y sin cupo → muestra paywall; con suscripción → sin cambios (sheet directo, sin consultar el cupo).
- [x] 6.3 `test/unit/features/article_summary/presentation/cubit/article_summary_cubit_test.dart` -- caso: al alcanzar el límite, `ArticleSummaryLimitReached` lleva el `dailyLimit` correcto (2 o 25 según el mock de suscripción/status usado).
- [x] 6.4 Widget test del bottom sheet -- el texto de límite alcanzado muestra "2" cuando `dailyLimit` es 2, y "25" cuando es 25 (no un valor fijo).
- [x] 6.5 Suite completa de `flutter test` corrida en verde, incluido `neutral_spanish_test.dart`.

## 7. Despliegue

- [x] 7.1 Confirmado con el usuario: desplegar a ambos proyectos (`reevo` prod y `reevo-dev` dev).
- [x] 7.2 `summarize-article` y `enrich-mentions` desplegadas en ambos proyectos. Sin migración (no hubo cambios de schema en este change).
- [x] 7.3 Correr `flutter analyze` y `flutter test` localmente antes de subir la rama (hecho, ambos en verde); abrir PR y esperar el check `analyze-and-test` en verde antes de mergear. Tras mergear, volver a `main`, actualizarla, y borrar la rama. PR #21 mergeado 2026-09-04; probado manualmente por el usuario en simulador (incluye los fixes de overflow del bottom sheet, PR #23 y #24, no parte de este change pero tocan el mismo widget).
