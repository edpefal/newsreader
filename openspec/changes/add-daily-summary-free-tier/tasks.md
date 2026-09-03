## 1. Backend — tabla y RPC del cupo gratis semanal

- [x] 1.1 Migración: crear tabla `daily_summary_free_usage` (`user_id uuid primary key references auth.users`, `week_start date not null`, `used boolean not null default false`, `updated_at timestamptz not null default now()`), con RLS (solo el propio usuario puede leer su fila, sin insert/update directo — igual que `ai_usage_daily`).
- [x] 1.2 Migración: función `check_and_record_daily_summary_free_usage()` — `security definer`, mismo patrón de lock de fila (`for update`) + reset cuando `week_start` no es el lunes de la semana ISO en curso + chequeo-e-incremento atómico, devolviendo `(allowed boolean, used boolean)`. A diferencia de `check_and_record_ai_usage`, esta función NO incrementa antes de invocar a Gemini — se llama recién después de persistir el `DailySummary` (ver design.md, "El descuento del cupo gratis ocurre..."), así que su contrato es "marcar usado" (siempre debe poder pasar de `false` a `true`), no "chequear y permitir".
- [x] 1.3 Migración separada (o la misma): función `get_daily_summary_free_usage_status()` — `security definer`, solo lectura, para que el cliente consulte su propio estado sin necesidad de generar (usada en el próximo `SyncUserData`/pantalla de resúmenes).
- [x] 1.4 `revoke all` / `grant execute ... to authenticated` en ambas funciones, igual que `check_and_record_ai_usage`.

## 2. Backend — `summarize-articles`

- [x] 2.1 Antes del chequeo de `hasActiveEntitlement`, no cambia — se mantiene igual.
- [x] 2.2 Si no hay suscripción activa: llamar a `get_daily_summary_free_usage_status()` (o la función que resuelva 1.3) para saber si hay cupo disponible en la semana en curso; si no lo hay, responder `subscription_required` (mismo error que hoy, sin invocar a Gemini) — reemplaza el rechazo incondicional actual.
- [x] 2.3 Si hay cupo disponible (o hay suscripción activa), continuar al chequeo existente de `daily_summary_already_generated` sin cambios.
- [x] 2.4 Tras persistir el `DailySummary` exitosamente: si el usuario no tiene suscripción activa, llamar a `check_and_record_daily_summary_free_usage()` para marcar el cupo semanal como usado.
- [x] 2.5 Actualizar/agregar tests de la función: se extrajo la decisión "hay cupo disponible" a `free_usage.ts` (función pura, mismo patrón que `entitlement.ts`) con `free_usage_test.ts` cubriendo sin fila / `used: false` / `used: true`. No existe un harness de integración para el handler completo de `summarize-articles` (los tests existentes de esta función son todos unitarios sobre lógica pura extraída), así que no hay dónde agregar los casos de integración end-to-end mencionados originalmente.

## 3. Cliente — dominio y datos

- [x] 3.1 Nueva entidad `DailySummaryFreeUsageStatus` (`usedThisWeek: bool`, `weekStart: DateTime`) en `core/domain/entities/`, con getter `available` (o equivalente) espejando `AiUsageStatus.remaining`/`.limitReached`.
- [x] 3.2 Nuevo modelo Hive `DailySummaryFreeUsageModel` (`weekStart: DateTime`, `used: bool`) con su `HiveType` (siguiente `typeId` libre) y `.g.dart` generado.
- [x] 3.3 Nuevo datasource local (`DailySummaryFreeUsageLocalDataSource` + `HiveDailySummaryFreeUsageDatasource`), mismo patrón que `AiUsageLocalDataSource`/`HiveAiUsageDatasource`: `get()`, `applyRemote(model)`, `recordLocalUsage()` (marca `used = true` para la semana actual, reseteando si `weekStart` cambió).
- [x] 3.4 Repositorio: se creó `DailySummaryFreeUsageRepository`/`DailySummaryFreeUsageRepositoryImpl` hermano de `AiUsageRepository` (más claro que sobrecargar uno existente, dado que `ai-usage-budget` documenta explícitamente que ese repositorio es propio de `article-summaries`), con `getStatus()` y `recordLocalUsage()`.
- [x] 3.5 Registrar el nuevo box/datasource/repositorio en `core/di/injection.dart`.
- [x] 3.6 Abrir el nuevo box de Hive en `main.dart`, junto a los existentes.
- [x] 3.7 `SyncUserData`: agregado `_syncDailySummaryFreeUsage` leyendo `daily_summary_free_usage`, mismo patrón solo-lectura que `_syncAiUsage`.

## 4. Cliente — generación y estado

- [x] 4.1 `GenerateDailySummary.execute()`: tras persistir el `DailySummary` exitosamente, si no hay suscripción activa, llamar a `recordDailySummaryFreeUsage()` — mismo punto donde `GenerateArticleSummary` llama a `recordLocalUsage()`, nunca en el catch ni en el early-return por excepciones esperadas.
- [x] 4.2 `SummariesCubit.generateTodaySummary()`: cambiar la lógica de decisión — si `isSubscribed`, generar directo (sin cambios); si no, consultar `getStatus()`; si hay cupo, generar directo (sin paywall); si no hay cupo, mostrar el paywall igual que hoy.
- [x] 4.3 `SummariesState`/`SummariesLoaded`: agregados `isSubscribed`/`freeTierAvailable`, poblados en `loadSummaries()` y tras generar con éxito.
- [x] 4.4 `SummariesView` (o el widget que corresponda): mostrar el indicador "te queda 1 gratis esta semana" cuando hay cupo y no hay suscripción; mostrar el mensaje inline de cupo agotado ("vuelve el lunes o suscríbete") cuando no hay cupo ni suscripción, en vez de ir directo al paywall.

## 5. Localización

- [x] 5.1 Agregar claves nuevas (`summariesFreeTierAvailable` o similar para el contador, `summariesFreeTierExhausted` o similar para el mensaje de cupo agotado) en `lib/l10n/app_en.arb` (template completo).
- [x] 5.2 Traducir a español neutro con tuteo en `lib/l10n/app_es.arb`, verificando manualmente que no haya voseo (no cubierto por `neutral_spanish_test.dart` salvo que se agregue ahí).
- [x] 5.3 Traducir al francés en `lib/l10n/app_fr.arb` — a diferencia de lo asumido en el proposal, `app_fr.arb` ya tiene traducción real completa (no placeholders en inglés; CLAUDE.md está desactualizado en ese punto), y `test/unit/l10n/french_translation_completeness_test.dart` falla si una clave nueva queda en inglés, así que se tradujo de verdad en vez de copiar el string en inglés.
- [x] 5.4 Correr `flutter gen-l10n` para regenerar `lib/l10n/app_localizations.dart`.

## 6. Tests

- [x] 6.1 `test/unit/core/data/datasources/hive_daily_summary_free_usage_datasource_test.dart` — equivalente a `hive_ai_usage_datasource_test.dart`, más casos de `weekStartOf`.
- [x] 6.2 `test/unit/core/data/repositories/daily_summary_free_usage_repository_impl_test.dart` — equivalente a `ai_usage_repository_impl_test.dart`.
- [x] 6.3 `test/unit/features/summaries/domain/usecases/generate_daily_summary_test.dart` — casos: genera y registra uso gratis sin suscripción; no registra uso en `NoArticlesTodayException`/`DailySummaryAlreadyGeneratedException`; con suscripción activa no registra uso gratis.
- [x] 6.4 `test/unit/features/summaries/presentation/cubit/summaries_cubit_test.dart` — casos: sin suscripción y con cupo → genera sin paywall; sin suscripción y sin cupo → muestra paywall (tests preexistentes, ahora con cupo agotado por default); con suscripción → nunca consulta el cupo; `loadSummaries()`/`SummariesLoaded` reflejan el estado del cupo correctamente.
- [x] 6.5 Widget test de la pantalla de resúmenes cubriendo el indicador de cupo disponible, el mensaje de cupo agotado, y que ninguno se muestra con suscripción activa. También se actualizó `free_usage_test.ts` (Deno) para la función pura nueva del backend.

## 7. Despliegue

- [x] 7.1 Confirmado con el usuario: desplegar a ambos proyectos (`reevo` prod y `reevo-dev` dev).
- [x] 7.2 Migración y Edge Function `summarize-articles` desplegadas en ambos proyectos. En `reevo-dev` se encontró primero un desalineamiento en la tabla de historial de migraciones (14 versiones remotas con nombres que coincidían 1:1 con archivos ya existentes en el repo, solo con timestamps de versión distintos -- confirmado vía `list_tables` que el schema real ya reflejaba esas migraciones). Se resolvió con `supabase migration repair` (bookkeeping únicamente, sin tocar schema) antes de empujar la migración nueva. El link del repo quedó restaurado a `reevo` (prod, el default) al terminar.
- [ ] 7.3 Correr `flutter analyze` y `flutter test` localmente antes de subir la rama (hecho, ambos en verde); abrir PR y esperar el check `analyze-and-test` en verde antes de mergear (ver flujo de trabajo en CLAUDE.md).
