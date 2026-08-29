## Context

`ObservabilityClient` (`lib/core/observability/observability_client.dart`) es hoy la única abstracción de telemetría del proyecto. Ya tiene `trackEvent(String name, {Map<String, Object?>? properties})` y `setUserId(String? userId)`, pero `SentryObservabilityClient` implementa `trackEvent` como un breadcrumb de Sentry -- contexto para futuros error reports, no un evento que llegue a ningún dashboard de producto. El comentario del método ("Sin call sites en este change") confirma que nunca se usó.

`ObservabilityClient` ya está inyectado por constructor en `LoginCubit`, `AddSourceCubit`, `ImportOpmlCubit`, `SourceDetailCubit`, `InboxCubit`, `ArticleSummaryCubit` y `SummariesCubit`, y `setUserId` se llama desde un único lugar (`main.dart`, atado al cambio de sesión). `AppConfig` (`core/config/app_config.dart`) ya separa credenciales dev/prod (Supabase URL/key, Sentry DSN) según el dart-define `APP_ENV`. `GoRouter` (`presentation/app/router.dart:207`) no registra ningún `observers` hoy.

Ver proposal.md para la motivación completa (por qué PostHog, por qué no Supabase propio, por qué no autocapture).

## Goals / Non-Goals

**Goals:**
- Una sola interfaz (`TelemetryClient`) como punto de entrada para error-tracking y product-analytics, reutilizando el mismo wiring de DI y de identidad de usuario que ya existe.
- Capturar `screen_view` sin instrumentar cada pantalla a mano.
- Instrumentar manualmente los 8 eventos de producto listados en el proposal, en los cubits donde el `TelemetryClient` ya está disponible.

**Non-Goals:**
- No se implementa `article_marked_read`, funnels, session replay, ni A/B testing (ver spec: alcance explícito).
- No se cambia el comportamiento de `observability` (error-tracking): mismas reglas de captura, asociación de usuario y separación dev/prod que ya existen.
- No se construye ningún dashboard propio -- se usa el dashboard de PostHog tal cual.

## Decisions

- **Fan-out en una sola interfaz, con rename a `TelemetryClient`**: se descartó mantener `ObservabilityClient` sin cambios (nombre ya no describiría bien su responsabilidad) y también se descartó una interfaz `AnalyticsTracker` separada (hubiera duplicado el `setUserId`/reset en `main.dart` y obligado a inyectar dos clientes en cada cubit que necesite ambas cosas). El rename toca la interfaz, la implementación concreta, el binding en `core/di/injection.dart`, y los ~7 call sites que ya inyectan el tipo -- todo dentro de este mismo change.
- **PostHog en vez de Supabase propio**: se evaluó loguear eventos directo en una tabla de Supabase (mismo patrón que `SupabaseAuthClient`/`SupabaseCloudSyncClient`, sin SDK de terceros ni cambio de privacy label). Se descartó para esta primera versión porque no da un dashboard de uso listo (`screen_view` por pantalla, eventos por acción) sin construirlo a mano, y el SDK de PostHog ya resuelve batching/flush de eventos de alta frecuencia. Queda como alternativa válida a reconsiderar si en el futuro se prioriza cero-dependencias por sobre tener un dashboard ya armado.
- **Autocapture desactivado**: `Posthog().setup()` se configura con autocapture off; solo se registran los 8 eventos instrumentados a mano + `screen_view`. Alternativa descartada: dejar autocapture prendido para tener cobertura total desde el día uno -- se descarta porque genera ruido (eventos sin nombre significativo) y consume cuota del free tier más rápido sin aportar señal accionable.
- **`screen_view` vía `NavigatorObserver`**: se agrega un observer propio (no el `SentryNavigatorObserver` de Sentry, que es para performance tracing) registrado en `observers` de `GoRouter`, leyendo el nombre de ruta desde `RouteSettings.name`/`GoRouterState`. Alternativa descartada: llamar `trackEvent('screen_view', ...)` a mano en el `initState` de cada una de las 8 pantallas -- se descarta por ser repetitivo y fácil de olvidar en pantallas nuevas.
- **API key de PostHog en `AppConfig`, dev/prod**: mismo patrón que `sentryDsn`/`supabaseUrl` (`_devPostHogKey`/`_prodPostHogKey`, resuelto por `APP_ENV`). Esto separa los eventos de desarrollo local de los de producción en dos proyectos de PostHog distintos, igual que ya pasa con Sentry y Supabase (`reevo`/`reevo-dev`, ver sección "Proyectos de Supabase" de CLAUDE.md).
- **Host de PostHog: cloud US por defecto** (`app.posthog.com`), sin necesidad de hosting EU ni self-host, consistente con que la privacidad "estándar" alcanza para este caso (definido en la sesión de exploración).

- **`daily_summary_viewed` descartado durante la implementación**: al construir el `ScreenViewObserver` (ver más abajo) se hizo evidente que un evento bespoke para "ver un resumen diario" sería casi idéntico al `screen_view` automático de la ruta `/summaries/:date` -- la misma razón por la que `article_marked_read` ya estaba fuera de alcance frente a `/article/:id`. Se descartó en vez de implementarlo, y se actualizó proposal.md/specs para reflejarlo.

## Risks / Trade-offs

- [El rename de `ObservabilityClient` → `TelemetryClient` toca ~10 archivos y puede generar conflictos si hay otro change en curso tocando esos mismos cubits] → Mitigar haciendo el rename como primer paso, aislado, antes de agregar la lógica de PostHog, para que el diff de "solo renombrar" sea fácil de revisar por separado del diff de "agregar PostHog".
- [Nuevo SDK de terceros (`posthog_flutter`) requiere actualizar el privacy label / Data Safety de App Store y Play Store, y potencialmente un `PrivacyInfo.xcprivacy`] → Tarea explícita en tasks.md antes de considerar el change listo para subir a review de las tiendas; no bloquea el desarrollo ni los tests.
- [Si la app crece en usuarios activos diarios, agregar `article_marked_read` más adelante puede consumir el free tier de PostHog más rápido que los 8 eventos actuales] → Aceptado como riesgo conocido y explícitamente fuera de alcance (ver spec); se puede reevaluar cuando haga falta, sin que esto bloquee la v1.
