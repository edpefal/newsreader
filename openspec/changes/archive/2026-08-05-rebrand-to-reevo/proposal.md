## Why

La app ya se llama Reevo (el bundle id de Android/iOS es `com.artlab.reevo`), pero el texto "Newsletter Hub" sigue apareciendo en varias pantallas y en la documentación del proyecto — un remanente del nombre anterior que genera inconsistencia entre lo que ve el usuario y la identidad real del producto.

## What Changes

- Reemplazar todas las apariciones visibles de "Newsletter Hub" por "Reevo" en la UI: pantalla de login, título de la app (`MaterialApp.router`), página de error del router, mensaje de bienvenida del onboarding del Inbox.
- Actualizar el test de widget que depende del texto de bienvenida (`inbox_screen_test.dart`) para que siga verificando el mismo comportamiento con el texto nuevo.
- Actualizar la documentación del proyecto (`README.md`, `PRD.md`, `CLAUDE.md`) y la `description` de `pubspec.yaml` para referirse a Reevo en vez de Newsletter Hub.
- Actualizar el nombre de display de la app en Android (`android:label` en `AndroidManifest.xml`) y iOS (`CFBundleDisplayName`/`CFBundleName` en `Info.plist`), hoy "newsreader"/"Newreader", a "Reevo".
- Fuera de alcance explícito: no se renombra el paquete Dart (`name: newsreader` en `pubspec.yaml`, que determina todos los imports `package:newsreader/...`) ni el nombre del directorio del repositorio — es un cambio estructural mucho más amplio y riesgoso, no pedido, y sin impacto visible para el usuario final.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

(ninguna — cambio de copy/branding y metadata, sin cambios de comportamiento observable)

## Impact

- UI: `lib/features/auth/presentation/screens/login_screen.dart`, `lib/features/inbox/presentation/screens/inbox_screen.dart`, `lib/presentation/app/router.dart`, `lib/presentation/app/app.dart`.
- Tests: `test/widget/features/inbox/inbox_screen_test.dart`.
- Documentación: `README.md`, `PRD.md`, `CLAUDE.md`, `pubspec.yaml` (campo `description`).
- Configuración de plataforma: `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`.
