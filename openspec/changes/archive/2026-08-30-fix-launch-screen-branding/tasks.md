## 0. Corrección de asset (descubierta durante implementación)

- [x] 0.1 Generar `assets/reevo_logo_splash_light.png` (R negra sobre transparente) y `assets/reevo_logo_splash_dark.png` (R blanca sobre transparente) a partir de `assets/reevo_logo.png`, que resultó ser opaco (sin transparencia real) en vez del asset transparente asumido en el design original.
- [x] 0.2 Registrar los dos nuevos assets en `flutter: assets:` de `pubspec.yaml` y apuntar la config de `flutter_native_splash` (`image`, `image_dark`, `android_12.image`, `android_12.image_dark`) a ellos en vez de `reevo_logo.png`.

## 1. Configuración

- [x] 1.1 Agregar `flutter_native_splash` a `dev_dependencies` en `pubspec.yaml` y correr `flutter pub get`.
- [x] 1.2 Agregar bloque de configuración `flutter_native_splash` en `pubspec.yaml`: `image: assets/reevo_logo.png`, `color: "#FFFFFF"` (light), `color_dark` con un gris/negro neutro (ej. `#121212`), `image_dark: assets/reevo_logo.png`, `android_12` con su propio `image`/`icon_background_color` y `image_dark`/`icon_background_color_dark`.

## 2. Generación de assets

- [x] 2.1 Correr `dart run flutter_native_splash:create` para regenerar los assets nativos de iOS y Android.
- [x] 2.2 Confirmar que `ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png` ya no son 1x1 (verificar con `sips -g pixelWidth -g pixelHeight`) y que `LaunchScreen.storyboard` referencia el logo.
- [x] 2.3 Confirmar que `android/app/src/main/res/drawable*/launch_background.xml` (y las variantes `values-night`/`drawable-night` que agregue la herramienta) referencian el logo con el color de fondo correcto por tema.

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` — no debe haber warnings nuevos.
- [x] 3.2 Pedirle al usuario que corra la app en simulador iOS y Android, en modo claro y oscuro, para confirmar visualmente que el logo se ve centrado y con buen contraste en ambos fondos (no automatizar taps ni lanzar `flutter run`, según CLAUDE.md).
- [x] 3.3 Si el usuario reporta que el color oscuro no calza bien con el tema de la app, ajustar `color_dark`/`icon_background_color_dark` en `pubspec.yaml` y repetir el paso 2.1.
