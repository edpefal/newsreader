## Why

App Store Connect marca un warning en la validación de assets ("App Icon and Launch Image Assets Validation"): la launch image de iOS sigue en el placeholder default de Flutter (PNG 1x1 transparente), igual que el `launch_background.xml` de Android, que solo pinta un color sólido sin logo. Hay que reemplazar ambos por una pantalla de arranque real con el logo de Reevo, adaptada a light/dark, antes de que esto bloquee una futura revisión de Apple.

## What Changes

- Agregar el paquete `flutter_native_splash` como dependencia de desarrollo para generar los assets nativos de launch screen de iOS y Android a partir de una única configuración declarativa.
- Configurar la splash screen con: fondo blanco y logo de Reevo (`assets/reevo_logo.png`) centrado en modo claro; fondo oscuro y el mismo logo centrado en modo oscuro (dark theme del sistema).
- Regenerar los assets nativos (`ios/Runner/Assets.xcassets/LaunchImage.imageset/*`, `ios/Runner/Base.lproj/LaunchScreen.storyboard`, `android/app/src/main/res/drawable*/launch_background.xml` y los `values*/styles.xml` que agrega la librería) vía el comando de generación del paquete — no se edita el XML/storyboard a mano.
- No se toca el ícono de la app (`flutter_launcher_icons`), solo la launch image/splash screen.

## Capabilities

### New Capabilities
- `app-launch-screen`: pantalla de arranque nativa (iOS + Android) con el logo de Reevo centrado y fondo que respeta el tema claro/oscuro del sistema.

### Modified Capabilities
(ninguna — no hay spec existente de branding/launch screen)

## Impact

- `pubspec.yaml`: nueva dev dependency `flutter_native_splash` + bloque de configuración `flutter_native_splash`.
- iOS: `ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png`, `ios/Runner/Base.lproj/LaunchScreen.storyboard` (regenerados).
- Android: `android/app/src/main/res/drawable/launch_background.xml`, `android/app/src/main/res/drawable-v21/launch_background.xml`, y los `mipmap`/`values*` que agregue la herramienta (regenerados).
- No afecta código Dart de la app (`lib/`) ni arquitectura de features — es un cambio de configuración/assets nativos.
