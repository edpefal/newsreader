## 1. UI

- [x] 1.1 En `lib/features/auth/presentation/screens/login_screen.dart:37`, reemplazar `'Newsletter Hub'` por `'Reevo'`.
- [x] 1.2 En `lib/features/inbox/presentation/screens/inbox_screen.dart:360`, reemplazar `'Bienvenido a Newsletter Hub'` por `'Bienvenido a Reevo'`.
- [x] 1.3 En `lib/presentation/app/router.dart:217`, reemplazar `'Newsletter Hub'` por `'Reevo'`.
- [x] 1.4 En `lib/presentation/app/app.dart:97`, reemplazar el `title: 'Newsletter Hub'` de `MaterialApp.router` por `title: 'Reevo'`.

## 2. Tests

- [x] 2.1 En `test/widget/features/inbox/inbox_screen_test.dart:80`, actualizar el `expect` de `'Bienvenido a Newsletter Hub'` a `'Bienvenido a Reevo'`.
- [x] 2.2 Correr `flutter test test/widget/features/inbox/inbox_screen_test.dart` y confirmar que pasa.

## 3. Documentación y metadata

- [x] 3.1 Actualizar el título/encabezado de `README.md` de "Newsletter Hub" a "Reevo".
- [x] 3.2 Actualizar el encabezado de `PRD.md` ("PRD: Newsletter Hub (MVP)") a "Reevo".
- [x] 3.3 Actualizar el encabezado de `CLAUDE.md` ("Newsletter Hub — Instrucciones para Claude") a "Reevo — Instrucciones para Claude".
- [x] 3.4 Actualizar `description:` en `pubspec.yaml` de "Newsletter Hub — centralize your newsletters outside of email." a la versión con "Reevo".
- [x] 3.5 (no anticipada en la propuesta original, agregada durante la verificación 5.3) Actualizar encabezados de `PROGRESS.md`, `USER_STORIES.md` y `SOLUTION_SPEC.md`, que también decían "Newsletter Hub (MVP)".

## 4. Configuración de plataforma

- [x] 4.1 En `android/app/src/main/AndroidManifest.xml`, cambiar `android:label="newsreader"` a `android:label="Reevo"`.
- [x] 4.2 En `ios/Runner/Info.plist`, cambiar `CFBundleDisplayName` (hoy "Newsreader") y `CFBundleName` (hoy "newsreader") a "Reevo".

## 5. Verificación final

- [x] 5.1 Correr `flutter analyze` y confirmar que no hay warnings.
- [x] 5.2 Correr `flutter test` (suite completa) y confirmar que todo pasa.
- [x] 5.3 Buscar referencias remanentes con `grep -rni "newsletter hub" lib/ test/ *.md pubspec.yaml android/ ios/` y confirmar que no queda ninguna (fuera del historial archivado de `openspec/changes/archive/`).
