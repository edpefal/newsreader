## Why

Hoy la app no tiene ningún tipo de observabilidad: no hay captura de excepciones no manejadas, ni un lugar centralizado donde reportar los errores que ya se atrapan y se descartan. Hay 19 bloques `catch (_)` en `lib/` que hoy tragan el error en silencio (muchos de ellos son justo los catch-all que el change `add-localized-error-codes` mapea a un `AppErrorCode` genérico para el usuario) — cuando algo falla en producción, no queda ningún rastro técnico de qué pasó. Se agrega un proveedor de observabilidad detrás de una abstracción propia para poder reportar excepciones y, más adelante, cambiar de proveedor sin tocar el resto de la app.

## What Changes

- Se crea la abstracción `ObservabilityClient` en `core/observability/`, con métodos para capturar excepciones, mensajes, breadcrumbs, eventos custom (`trackEvent`, sin call sites todavía) y asociar/desasociar el usuario actual.
- Se agrega la implementación concreta con Sentry (`sentry_flutter`), registrada una única vez en `core/di/injection.dart`, siguiendo el mismo patrón que `HttpClient`/`FeedParser`/`AuthClient`.
- `main.dart` inicializa Sentry al arrancar la app y queda cubierto para excepciones no manejadas de Flutter y de Dart (zonas no capturadas).
- `AuthClient.authStateChanges` alimenta `ObservabilityClient.setUserId`, en el mismo lugar donde ya se hace `subscriptionStatusProvider.identify()`/`.reset()`.
- Se auditan los 19 `catch (_)` existentes en `lib/`: cada uno pasa a capturar la excepción real (`catch (e, st)`) y reportarla vía `ObservabilityClient.captureException` antes de continuar con el manejo actual (mapear a `AppErrorCode`, ignorar por ser best-effort, etc.). Ninguno cambia su comportamiento visible para el usuario — solo se instrumenta lo que ya pasaba.
- Se agrega `AppConfig.sentryDsn`, con un proyecto de Sentry separado para dev y otro para prod, siguiendo el mismo patrón que ya existe para las credenciales de Supabase.
- En builds de debug/dev no se reporta a Sentry (o se reporta con un flag distinguible) para no ensuciar el proyecto de producción con ruido de desarrollo local.

## Capabilities

### New Capabilities
- `observability`: la app reporta excepciones no manejadas y errores internamente capturados a un proveedor de observabilidad, asociados al usuario cuando hay sesión activa, sin exponer ese detalle técnico al usuario final.

### Modified Capabilities
(ninguna — no cambia el comportamiento visible de ninguna capability existente; los `catch (_)` se instrumentan pero conservan exactamente el mismo comportamiento observable por el usuario)

## Impact

- **Nuevo código**: `core/observability/observability_client.dart` (interfaz), `core/observability/sentry_observability_client.dart` (implementación).
- **Dependencia nueva**: `sentry_flutter` en `pubspec.yaml`.
- **Modificados**: `lib/main.dart` (init de Sentry + hooks de error globales), `core/di/injection.dart` (registro del cliente), `core/config/app_config.dart` (DSN dev/prod), `core/auth/auth_client.dart`/`supabase_auth_client.dart` (no cambia su interfaz, pero `main.dart` pasa a llamar `setUserId` en el listener existente).
- **19 archivos con `catch (_)`** listados en el design.md pasan a `catch (e, st)` + reporte, sin cambiar su lógica de negocio.
- **Config externa**: requiere crear dos proyectos en Sentry (dev y prod) y obtener sus DSN antes de mergear — no es un paso automatizable desde el código.
