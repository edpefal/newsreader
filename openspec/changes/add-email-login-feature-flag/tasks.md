## 1. Abstracción de feature flags

- [x] 1.1 Crear `core/feature_flags/feature_flag_client.dart` con `isEnabled(String key)` y `Stream<void> changes`, y `feature_flag_keys.dart` con `emailLogin = 'email-login'`
- [x] 1.2 Implementar `PostHogFeatureFlagClient`: `isEnabled` devuelve `false` ante `null`, valor no booleano o excepción; `changes` es un `StreamController.broadcast()` alimentado por `onFeatureFlags`
- [x] 1.3 Conectar el callback `onFeatureFlags` en `initPostHog` (`default_telemetry_client.dart`) sin exponer el SDK fuera de `core/`
- [x] 1.4 Registrar `FeatureFlagClient` en `core/di/injection.dart`
- [x] 1.5 Tests unitarios de `PostHogFeatureFlagClient` (falla segura, notificación de cambios) con mocktail

## 2. Evaluación por entorno

- [x] 2.1 En `initPostHog`, apagar `preloadFeatureFlags` y llamar `setPersonPropertiesForFlags({'environment': ...})` con el mismo valor que ya usa la super property, sin PII (una sola petición de flags, ya con el entorno)
- [x] 2.3 Reenviar el entorno para flags tras `Posthog().reset()` en `setUserId(null)` (el reset borra las propiedades de persona para flags; sin esto el flag queda apagado en el login) y cubrirlo con un test
- [x] 2.2 Test que verifique que solo se envía el entorno como dato de evaluación

## 3. Login detrás del flag

- [x] 3.1 Crear `EmailLoginAvailabilityCubit` (estado `bool` con `Equatable`) que lee `isEnabled(emailLogin)` al crearse y relee en cada emisión de `changes`; cancelar la suscripción en `close()`
- [x] 3.2 Registrarlo en `injection.dart` y proveerlo en `LoginScreen`/`router.dart` junto a `LoginCubit`
- [x] 3.3 En `LoginOptionsView`, mostrar el separador y el botón "Continuar con correo" solo si el cubit indica `true`; Google y Apple siempre
- [x] 3.4 Verificar que un flujo en `LoginEmailEntry`/`LoginCodeSent` no depende del cubit y no se interrumpe al apagarse el flag
- [x] 3.5 Tests de `EmailLoginAvailabilityCubit` con `bloc_test` (default apagado, flag llega después, flag se apaga)
- [x] 3.6 Actualizar `test/widget/login_screen_test.dart` y los widget tests de login: con flag apagado solo Google y Apple; con flag activo, los tres; flag que se activa con la pantalla visible

## 4. Verificación

- [x] 4.1 `flutter analyze` sin warnings y `flutter test` en verde
- [x] 4.2 Confirmar que el layout del login sigue centrado y con ancho máximo (`kLoginMaxContentWidth`) en ancho ≥840dp
- [x] 4.3 Comprobar en `git diff --stat` que `dart format` solo tocó los archivos modificados

## 5. Puesta en marcha (fuera del código, en PostHog)

- [x] 5.1 Crear el flag `email-login` condicionado por `environment = development` (creado el 2026-10-24, id 991102 en el proyecto Reevo Analytics; evalúa `true` en development y `false` en production) y verificar en una build de dev que aparece (confirmado por el usuario el 2026-10-25; el apagado en producción se verificó contra `/flags`)
- [ ] 5.2 Publicar la versión a producción con el flag apagado para prod
- [ ] 5.3 Subir el flag en prod a 10 %, 50 % y 100 %, revisando la alerta de Sentry `login_email_rate_limited` entre pasos
