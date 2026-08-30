## Why

Reevo no tiene ninguna capa de CI ni de CD hoy: no hay `.github/workflows`, ni fastlane, ni configuración de Codemagic. Cada regresión (tests rotos, warnings de `flutter analyze`) solo se detecta si el desarrollador corre los comandos a mano, y cada build de iOS para probar en dispositivo real se arma manualmente. Con el lanzamiento acercándose, conviene automatizar la verificación continua y dejar un camino repetible para subir builds a TestFlight antes de que el volumen de cambios lo haga más doloroso de resolver retroactivamente.

## What Changes

- Agregar un workflow de GitHub Actions que corra `flutter analyze` y `flutter test` en cada push y pull request contra `main`.
- Agregar una configuración de Codemagic (`codemagic.yaml`) que compile la app iOS con `--dart-define=APP_ENV=prod`, la firme automáticamente vía integración con la App Store Connect API (sin fastlane/match), y la suba al grupo interno de TestFlight — disparada manualmente ("Start new build" en la UI de Codemagic), no en cada push.
- El build number de iOS se autoincrementa contra el último build subido a TestFlight; la versión semántica (`X.Y.Z` en `pubspec.yaml`) se sigue actualizando a mano vía commit `chore:`, como hasta ahora.
- Documentar (nota de diseño, sin implementar) que la Fase 3 — release a producción/App Store — se disparará más adelante por git tag, cuando el lanzamiento esté más cerca.

Explícitamente fuera de alcance de este change:
- Cualquier pipeline de build/firma/distribución para Android (el usuario aún no va a lanzar Android).
- Automatizar la publicación a App Store (revisión de Apple) — solo llega hasta TestFlight interno.

## Capabilities

### New Capabilities
- `ci-pipeline`: verificación automática (lint + tests) en cada push/PR vía GitHub Actions.
- `ios-testflight-deploy`: build firmado y distribución manual a TestFlight interno vía Codemagic.

### Modified Capabilities
(ninguna — no se cambia el comportamiento de ninguna capability existente)

## Impact

- Código nuevo: `.github/workflows/ci.yml`, `codemagic.yaml` en la raíz del repo.
- Configuración externa (fuera del repo): integración de App Store Connect API key en Codemagic; grupo interno de TestFlight en App Store Connect.
- No afecta código de la app (`lib/`), no requiere cambios en `app_config.dart` ni nuevos `dart-define` más allá de `APP_ENV=prod` (que ya existe).
- No afecta Android (`android/key.properties`, `android/app/upload-keystore.jks` quedan sin usar en este change).
