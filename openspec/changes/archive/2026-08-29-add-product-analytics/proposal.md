## Why

Hoy la app no tiene visibilidad de uso de producto: no sabemos qué pantallas se visitan más ni qué acciones clave realiza la gente (agregar una fuente, generar un resumen, importar OPML, etc.). Sentry (capability `observability`) solo cubre errores/crashes, y su implementación ya tiene un método `trackEvent` sin ningún call site real -- señal de que esta necesidad ya se había anticipado pero nunca se resolvió con un proveedor pensado para eso. Se eligió PostHog por su tier gratuito generoso (1M eventos/mes) y por no requerir infraestructura nueva del lado del cliente más allá de un SDK.

## What Changes

- Agregar `posthog_flutter` como proveedor de analytics de producto, sin exponerlo fuera de `core/`.
- **BREAKING (interno, no afecta usuarios finales)**: renombrar la abstracción `ObservabilityClient` a `TelemetryClient` (y su implementación concreta), ya que pasa a cubrir tanto error-tracking (Sentry) como product-analytics (PostHog) detrás de una única interfaz. Todos los call sites existentes (~7 cubits + `main.dart` + `core/di/injection.dart`) se actualizan al nuevo nombre.
- `TelemetryClient.trackEvent` deja de ser un breadcrumb de Sentry sin uso real y pasa a enviar el evento a PostHog.
- `TelemetryClient.setUserId` pasa a identificar (o desasociar) al usuario tanto en Sentry como en PostHog, con las mismas reglas de privacidad que ya aplican a Sentry (nunca email, solo id de usuario).
- Agregar un `NavigatorObserver` propio registrado en `GoRouter` (`presentation/app/router.dart`) que dispara un evento `screen_view` en cada navegación, sin instrumentar cada pantalla a mano.
- Instrumentar manualmente (autocapture de PostHog desactivado) los siguientes eventos de producto: `login_completed`, `source_added`, `opml_import_completed`, `source_deleted`, `sync_triggered`, `summary_requested`, `favorite_toggled`. (`daily_summary_viewed` se descartó durante la implementación: el `screen_view` automático de `/summaries/:date` ya cubre esa señal, igual que `article_marked_read` con `/article/:id` -- ver design.md.)
- Agregar `_devPostHogKey` / `_prodPostHogKey` a `AppConfig`, siguiendo el mismo patrón dev/prod ya usado para el DSN de Sentry y las URLs de Supabase.
- Fuera de alcance en este change: `article_marked_read` (evento de mayor volumen, se evalúa después), funnels, session replay, y A/B testing (features de PostHog no usadas en esta primera integración).

## Capabilities

### New Capabilities
- `product-analytics`: define qué eventos de producto se capturan, cómo se asocian (o desasocian) al usuario activo, y las reglas de privacidad para ese tracking (sin PII, autocapture desactivado).

### Modified Capabilities
(ninguna -- `observability` no cambia su comportamiento de error-tracking; el rename de `ObservabilityClient` a `TelemetryClient` es un detalle de implementación compartido entre ambas capabilities, no un cambio de requirement)

## Impact

- Nueva dependencia: `posthog_flutter` en `pubspec.yaml`.
- `lib/core/observability/observability_client.dart` → renombrado/extendido a `telemetry_client.dart` (interfaz `TelemetryClient`).
- `lib/core/observability/sentry_observability_client.dart` → implementación que sostiene Sentry + PostHog.
- `lib/core/di/injection.dart`: binding de `TelemetryClient`.
- `lib/main.dart`: init de PostHog junto al de Sentry; llamadas a `setUserId` ya existentes se mantienen, ahora fan-out a ambos proveedores.
- `lib/presentation/app/router.dart`: nuevo `NavigatorObserver` para `screen_view`.
- `lib/core/config/app_config.dart`: nuevas constantes de API key de PostHog (dev/prod).
- Cubits que ya inyectan el cliente (`LoginCubit`, `AddSourceCubit`, `ImportOpmlCubit`, `SourceDetailCubit`, `InboxCubit`, `ArticleSummaryCubit`, `SummariesCubit`): actualizan el tipo inyectado y agregan las llamadas a `trackEvent` correspondientes.
- Fuera del código: hay que actualizar el privacy label / Data Safety de App Store y Play Store para declarar PostHog como proveedor de analytics (tarea de store, no de código, pero bloqueante antes de subir a review).
