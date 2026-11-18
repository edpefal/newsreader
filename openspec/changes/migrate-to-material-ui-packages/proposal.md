> **Estado: backlog.** Se propone ahora para no perder el contexto, pero no se implementa hasta decidir subir a Flutter 3.47+ (ver design, D1 y D3). Mientras tanto el CI está fijado en Flutter 3.44.6.

## Why

Desde Flutter 3.47 el framework publica `material_ui` y `cupertino_ui` 1.0 como paquetes independientes, y `flutter analyze` marca `package:flutter/material.dart` como obsoleto ("Use package:material_ui/material_ui.dart instead"). Con una Flutter nueva, el CI sin versión fija falló en todos los PRs con 86 avisos `deprecated_member_use` (52 en `lib/`, 34 en `test/`); se resolvió fijando el CI en 3.44.6 (PR #81), pero eso solo aplaza el problema. La documentación oficial indica que los imports antiguos siguen compilando por ahora; no encontré fecha de retiro, así que no hay urgencia técnica, pero sí una deuda que crece con cada versión de Flutter.

## What Changes

- Subir Flutter a 3.47 o posterior en la máquina de desarrollo, en `ci.yml` (reemplazando el pin 3.44.6) y en `codemagic.yaml` (hoy `stable` sin versión).
- Agregar `material_ui` (y `cupertino_ui` solo si el código usa algo que lo requiera: hoy ningún archivo importa `package:flutter/cupertino.dart`) a `pubspec.yaml`.
- Reemplazar los imports de `package:flutter/material.dart` por `package:material_ui/material_ui.dart` en 50 archivos de `lib/` y 34 de `test/`, con la herramienta de migración oficial (`dart fix`; el nombre exacto del código de la regla debe confirmarse en la documentación del paquete antes de usarla).
- Ajustar la localización del framework: los delegados de Material (`GlobalMaterialLocalizations`) pasan a importarse de `material_ui`.
- **BREAKING (para usuarios con iOS 14):** Flutter 3.47 sube el mínimo de iOS de 13 a 15, y el proyecto está en 14.0 (`ios/Podfile` y 3 ajustes `IPHONEOS_DEPLOYMENT_TARGET` en `project.pbxproj`). Subirlo a 15.0 deja sin soporte a los dispositivos con iOS 14.
- Sin cambios de comportamiento ni de interfaz para el resto de los usuarios.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- **Cliente:** 84 archivos Dart (solo imports), `pubspec.yaml`, `ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj`, `l10n` generado si cambian los delegados.
- **CI/CD:** `.github/workflows/ci.yml` (cambiar el pin) y `codemagic.yaml`.
- **Dependencias de terceros:** hay que comprobar que las que dependen de Material (`google_fonts`, `flutter_widget_from_html`, `webview_flutter`, `file_picker`, `share_plus`, `purchases_flutter`, entre otras) soporten Flutter 3.47.
- **Usuarios:** los que están en iOS 14 dejarían de poder instalar actualizaciones. Conviene medir cuántos hay antes de decidir.
- **No sigue la regla de servidor y clientes publicados** de `CLAUDE.md`: no toca backend.
