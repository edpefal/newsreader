## Why

El login con correo y código ya está en la app, pero sus topes son globales, no por usuario: Supabase envía 30 correos por hora y Resend 100 por día. Un pico de registros nuevos, o un script, puede agotarlos y dejar sin acceso por correo a todos. Hoy no hay forma de controlar quién ve esa opción sin publicar una versión nueva de la app.

Poner el acceso por correo detrás de un feature flag, apagado por defecto, permite habilitarlo de forma gradual (dev primero, luego prod por porcentaje) y apagarlo desde un panel si hay abuso. PostHog ya está integrado como proveedor de analítica, y su plan free incluye 1M de requests de flags al mes, así que no hace falta ningún proveedor ni SDK nuevo.

## What Changes

- Nueva abstracción `FeatureFlagClient` en `core/feature_flags/`, respaldada por el SDK de PostHog que ya está en el proyecto. Ningún archivo de `domain/` o `presentation/` importa `posthog_flutter`.
- Un flag booleano `email-login`, **oculto por defecto**: sin red, sin flags cargados o con el flag inexistente, la opción de correo no se ofrece.
- La pantalla de login muestra el separador "o" y el botón "Continuar con correo" solo cuando el flag está activo. Google y Apple siempre se muestran.
- La vista inicial del login reacciona cuando los flags terminan de cargar, sin bloquear la pantalla ni mostrar un indicador de carga. El último valor conocido se conserva en disco entre arranques.
- Un flujo de correo ya iniciado (ingresando correo o código) no se interrumpe si el flag se apaga: el flag solo decide si se ofrece la entrada.
- Dev y prod comparten un solo proyecto de PostHog, así que el entorno se envía como propiedad de persona para la evaluación de flags (`setPersonPropertiesForFlags`), y el flag se condiciona por esa propiedad en el panel.
- El encendido en producción es gradual por porcentaje (10 % → 50 % → 100 %), revisando entre pasos la alerta de Sentry `login_email_rate_limited`. Estos pasos se hacen en el panel de PostHog y no requieren publicar versión.

## Capabilities

### New Capabilities
- `feature-flags`: lectura de feature flags remotos detrás de una abstracción de `core/`, con valor apagado por defecto, evaluación diferenciada por entorno y persistencia del último valor conocido.

### Modified Capabilities
- `user-auth`: el requirement "Inicio de sesión con correo y código" deja de ofrecer siempre la opción de correo; ahora depende del flag `email-login`. Los flujos de Google y Apple no cambian.

## Impact

- **Código**: `core/feature_flags/` (interfaz e implementación con PostHog), `core/di/injection.dart`, `main.dart` (propiedades de persona para flags tras `initPostHog`), `features/auth/presentation/` (`LoginCubit`/`LoginOptionsView`) y `test/` correspondientes.
- **Dependencias**: ninguna nueva; se usa `posthog_flutter` ya presente.
- **Servicios externos**: un flag nuevo en el proyecto de PostHog compartido, condicionado por `environment`.
- **Clientes ya publicados**: las versiones hasta `1.10.0+11` siguen mostrando el botón de correo, porque el flag solo gobierna la versión que lo incluya. No sirve como interruptor de emergencia para ellas.
- **Sin cambios de servidor**: no hay migraciones ni cambios en Edge Functions.
- **App Review**: sin impacto, el revisor entra con Sign in with Apple.
