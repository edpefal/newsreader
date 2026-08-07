## Why

La pantalla de login muestra un ícono genérico de Material (`Icons.auto_stories_outlined`) en vez del logo real de la app. El logo ya existe en el repo (`assets/reevo_logo.png`) y se usa para generar los íconos de instalación de Android/iOS, pero nunca se declaró como asset bundleable ni se usó dentro de la UI de la app.

## What Changes

- Declarar `assets/reevo_logo.png` como asset de Flutter en `pubspec.yaml` (hoy la sección `flutter:` no tiene ninguna lista de `assets`).
- En la pantalla de login (`login_screen.dart`), reemplazar el `Icon(Icons.auto_stories_outlined, ...)` por el logo real (`Image.asset('assets/reevo_logo.png', ...)`), manteniendo el tamaño y la disposición visual actual (centrado, arriba del texto "Reevo" y el subtítulo).

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

(ninguna — cambio puramente visual/de assets, sin comportamiento observable)

## Impact

- `pubspec.yaml`: se agrega la sección `assets:` dentro de `flutter:`.
- `lib/features/auth/presentation/screens/login_screen.dart`: reemplazo del ícono por el logo.
- No hay tests de widget existentes para `login_screen.dart` que dependan del ícono actual, así que no hay tests que actualizar.
