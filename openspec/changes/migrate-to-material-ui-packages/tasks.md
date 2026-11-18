## 1. Decisión y preparación

- [ ] 1.1 Medir en PostHog cuántos usuarios activos usan iOS 14 y decidir si se acepta subir el mínimo a iOS 15
- [ ] 1.2 Leer las notas de Flutter 3.47 y la guía oficial de migración a `material_ui`, y confirmar el nombre exacto de la regla de `dart fix`
- [ ] 1.3 Revisar con `flutter pub outdated` que los plugins del proyecto soporten Flutter 3.47, y buscar transiciones de página personalizadas

## 2. Dependencias y herramientas

- [ ] 2.1 Subir Flutter local a 3.47 o posterior
- [ ] 2.2 Agregar `material_ui` (y `cupertino_ui` solo si hace falta) a `pubspec.yaml` y correr `flutter pub get`

## 3. Migración

- [ ] 3.1 Aplicar la migración automática de imports en `lib/` y `test/` y revisar el diff
- [ ] 3.2 Ajustar los delegados de localización de Material y regenerar con `flutter gen-l10n` si hace falta
- [ ] 3.3 Subir `IPHONEOS_DEPLOYMENT_TARGET` y `platform :ios` a 15.0 (si se aceptó en 1.1) y regenerar pods
- [ ] 3.4 Formatear solo los archivos tocados y revisar `git diff --stat`

## 4. CI/CD

- [ ] 4.1 Cambiar el pin de Flutter en `.github/workflows/ci.yml` a la versión nueva
- [ ] 4.2 Fijar la versión de Flutter en `codemagic.yaml`

## 5. Verificación

- [ ] 5.1 `flutter analyze` sin avisos y `flutter test` en verde con la versión nueva
- [ ] 5.2 Build de TestFlight y recorrido manual en iPhone y en iPad (a cargo del usuario)
- [ ] 5.3 Actualizar `CLAUDE.md` si algún comando o regla cambia
