## 1. Rename ObservabilityClient → TelemetryClient

- [x] 1.1 Renombrar `lib/core/observability/observability_client.dart` a `telemetry_client.dart`, la interfaz `ObservabilityClient` a `TelemetryClient`, y actualizar sus doc comments (ya no es solo "observabilidad de errores").
- [x] 1.2 Renombrar `SentryObservabilityClient` (y su archivo) reflejando que ahora también sostiene PostHog (implementación concreta a definir en 2.x).
- [x] 1.3 Actualizar el binding en `core/di/injection.dart`.
- [x] 1.4 Actualizar los ~7 call sites que inyectan el tipo por constructor (`LoginCubit`, `AddSourceCubit`, `ImportOpmlCubit`, `SourceDetailCubit`, `InboxCubit`, `ArticleSummaryCubit`, `SummariesCubit`) y `main.dart`.
- [x] 1.5 Correr `flutter analyze` y confirmar que el rename no dejó referencias rotas.

## 2. Integrar PostHog

- [x] 2.1 Agregar `posthog_flutter` a `pubspec.yaml` y correr `flutter pub get`.
- [x] 2.2 Corrección respecto al plan original -- el plan free de PostHog solo permite 1 Project (crear un segundo pide tarjeta de crédito), así que dev y prod comparten el mismo proyecto/API key en vez de tener `_devPostHogKey`/`_prodPostHogKey` separadas como `sentryDsn`. `AppConfig.postHogApiKey` es una única constante con el token real del proyecto "Default project" de la organización Reevo.
- [x] 2.3 Inicializar PostHog en `main.dart`, con autocapture desactivado y host cloud US por defecto. Se inicializa antes que Sentry (`initPostHog` separado de `init`), porque el primer `setUserId` en `main.dart` ocurre antes de donde `init` arranca Sentry envolviendo `runApp`. `initPostHog` además registra la super property `environment` (`development`/`production` según `AppConfig.isProd`) para distinguir los eventos de cada entorno dentro del proyecto único.
- [x] 2.4 Implementar `trackEvent` en el `TelemetryClient` concreto enviando a PostHog (dejar de emitir el breadcrumb de Sentry sin uso real).
- [x] 2.5 Implementar `setUserId` haciendo fan-out: `identify`/`reset` en PostHog además del `setUser` de Sentry ya existente, sin incluir email en ningún caso.

## 3. Screen views

- [x] 3.1 Crear un `NavigatorObserver` propio (`ScreenViewObserver`) que dispare `trackEvent('screen_view', {...})` con el nombre de la ruta de destino (`route.settings.name`, que go_router resuelve como el patrón de la ruta, no la URL con el id real).
- [x] 3.2 Registrarlo en `observers` de `GoRouter` y, como cada `ShellRoute` crea su propio Navigator anidado que no hereda los observers del root, también en las 5 `ShellRoute` (`presentation/app/router.dart`). Corrección tras probar manualmente: una instancia compartida de `ScreenViewObserver` entre el root y las 5 branches rompía la app en runtime (`'observer.navigator == null': is not true` -- un `NavigatorObserver` no puede estar adjunto a más de un Navigator a la vez). Se cambió a una factory `_newScreenViewObserver()` que crea una instancia nueva en cada `observers: [...]`.

## 4. Instrumentar eventos de producto

- [x] 4.1 `login_completed` en `LoginCubit` (solo cuando `AuthResult.success`, no en cancelación), con propiedad `method` (google/apple).
- [x] 4.2 `source_added` en `AddSourceCubit`.
- [x] 4.3 `opml_import_completed` en `ImportOpmlCubit`, con `imported_count`/`failed_count`.
- [x] 4.4 `source_deleted`: corrección respecto al plan original -- el borrado vive en `SourcesCubit` (pantalla de lista), no en `SourceDetailCubit`. `SourcesCubit` no tenía `TelemetryClient` inyectado; se agregó el parámetro al constructor, se actualizó el binding en `injection.dart` y el test.
- [x] 4.5 `sync_triggered` en `InboxCubit.syncAndReload()` (no en las sincronizaciones automáticas -- `syncAfterSignIn`/`_silentFeedRefresh`/`syncInBackground` -- solo en la disparada explícitamente por el usuario, pull-to-refresh).
- [x] 4.6 `summary_requested` en `ArticleSummaryCubit`.
- [x] 4.7 `daily_summary_viewed` descartado durante la implementación: redundante con el `screen_view` automático de `/summaries/:date` (ver design.md). specs/proposal actualizados.
- [x] 4.8 `favorite_toggled`: corrección respecto al plan original -- vive en el usecase `ToggleFavorite` (no en un cubit), que ya tenía `TelemetryClient` inyectado. Propiedad `favorited: bool`.

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` y `flutter test`. Se agregaron tests nuevos para `trackEvent`/`setUserId` en `default_telemetry_client_test.dart` (mock del method channel `posthog_flutter`) y para `source_deleted` en `sources_cubit_test.dart`.
- [x] 5.2 Probar manualmente que los eventos y `screen_view` lleguen al proyecto de PostHog. Confirmado vía MCP en dev: `screen_view` (con `screen` = ruta de go_router, no URL con id real), `sync_triggered`, `favorite_toggled`, `login_completed` con `environment: development`. Confirmado en un segundo run lanzado explícitamente con `APP_ENV=prod`: `summary_requested` (x2) y `source_added` (x1) llegaron con `environment: production` -- confirma que la super property distingue correctamente ambos entornos dentro del mismo proyecto de PostHog. `opml_import_completed` sigue sin probarse.
- [x] 5.3 Confirmar que cerrar sesión desasocia al usuario de los eventos siguientes en PostHog (no solo en Sentry). Confirmado: el `distinct_id` cambia a uno anónimo tras `reset()` y el `person_id` no se reutiliza para la sesión nueva. Bug encontrado en el camino: `Posthog().reset()` borra todas las super properties, incluida `environment` -- los eventos posteriores al primer logout de la sesión quedaban con `environment: null`. Corregido en `default_telemetry_client.dart`: se guarda el valor de `environment` en un static y se re-registra inmediatamente después de `reset()`.

## 6. Deploy y compliance

- [x] 6.1 Confirmar con el usuario si hace falta un proyecto de PostHog separado para dev/prod (mismo criterio que Sentry/Supabase) antes de generar las API keys. Decisión inicial: sí, dos proyectos separados; revertida al toparse con el límite de 1 Project del plan free de PostHog (crear un segundo pide tarjeta de crédito) -- se usa un solo proyecto con la super property `environment` para distinguir dev/prod (ver 2.2/2.3).
- [x] 6.2 Actualizar el privacy label / Data Safety de App Store y Play Store para declarar PostHog como proveedor de analytics. Hecho en App Store Connect (App Privacy). Play Store queda fuera de alcance por ahora -- la app no se lanza en Android todavía.
- [x] 6.3 Verificado: `posthog_flutter` ya trae su propio `PrivacyInfo.xcprivacy` embebido en el plugin darwin (declara `UserDefaults` con razón `CA92.1`, y los datos de analytics/product-interaction como no-tracking). No requiere ninguna acción de nuestro lado -- Xcode lo agrega solo al bundlear el plugin.
