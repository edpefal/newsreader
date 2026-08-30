## 1. CI en GitHub Actions

- [x] 1.1 Crear `.github/workflows/ci.yml` con trigger en `push` a `main` y en `pull_request` contra `main`
- [x] 1.2 Configurar el job con `subosito/flutter-action` (canal stable, sin pin de versión específica salvo la que ya usa el proyecto) y `flutter pub get`
- [x] 1.3 Agregar el paso `flutter analyze`
- [x] 1.4 Agregar el paso `flutter test`
- [x] 1.5 Verificar en un PR de prueba que el chequeo aparece y bloquea/aprueba correctamente según el resultado

## 2. Codemagic: build y firma de iOS

- [x] 2.1 Conectar el repositorio a Codemagic (paso manual del usuario en la UI de Codemagic)
- [x] 2.2 Configurar la integración de App Store Connect API key en Codemagic para `com.artlab.reevo` (paso manual del usuario, credencial no versionada)
- [x] 2.3 Crear `codemagic.yaml` en la raíz del repo con un workflow `ios-testflight` de trigger manual (sin `triggering` automático por push)
- [x] 2.4 Configurar el paso de build con `flutter build ipa --dart-define=APP_ENV=prod`
- [x] 2.5 Configurar firma automática de iOS vía la integración de App Store Connect API (`ios_signing` con `distribution_type: app_store` y gestión automática de certificados/profiles)
- [x] 2.6 Configurar el build number para que se resuelva contra el último subido a TestFlight (usar la variable/función de Codemagic para el siguiente build number de App Store Connect)

## 3. Codemagic: distribución a TestFlight

- [x] 3.1 Configurar la publicación (`publishing.app_store_connect`) para subir al grupo interno de TestFlight, sin marcar el build para revisión de App Store
- [x] 3.2 Ejecutar un primer build manual desde la UI de Codemagic y confirmar que compila, firma y sube correctamente
- [x] 3.3 Confirmar en App Store Connect / TestFlight que el build aparece en el grupo interno y es instalable en un dispositivo de prueba

## 4. Documentación

- [x] 4.1 Agregar a `README.md` una sección breve sobre cómo correr un build manual de TestFlight (dónde está el botón, qué credenciales necesita quien lo use)
- [x] 4.2 Confirmar que `openspec/specs/ci-pipeline/spec.md` y `openspec/specs/ios-testflight-deploy/spec.md` quedan listos para archivar una vez verificado el flujo end-to-end
