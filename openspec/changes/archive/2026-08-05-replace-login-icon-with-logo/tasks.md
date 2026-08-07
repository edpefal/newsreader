## 1. Declarar el asset

- [x] 1.1 En `pubspec.yaml`, agregar la sección `assets:` dentro de `flutter:` con `assets/reevo_logo.png`.
- [x] 1.2 Correr `flutter pub get` para que el asset quede registrado.

## 2. Reemplazar el ícono en login

- [x] 2.1 En `lib/features/auth/presentation/screens/login_screen.dart:30-34`, reemplazar `Icon(Icons.auto_stories_outlined, size: 72, color: Theme.of(context).colorScheme.primary)` por `Image.asset('assets/reevo_logo.png', height: 72)`.

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` y confirmar que no hay warnings.
- [x] 3.2 Correr `flutter test` (suite completa) y confirmar que todo pasa.
- [x] 3.3 Levantar la app (`flutter run`) y confirmar visualmente que el logo se ve bien proporcionado en la pantalla de login, sin distorsión ni recorte, con el mismo espaciado que tenía el ícono anterior.
