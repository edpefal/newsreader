## 1. AddSourceScreen: ciclo de vida del SnackBar de error de detección

- [x] 1.1 Extraer la construcción del `SnackBar` de `AddSourceFeedDiscoveryFailed` a un método propio que arme el `content` como un `Row` con el mensaje de error (expandido) y un `IconButton(Icons.close)` que llame a `ScaffoldMessenger.of(context).hideCurrentSnackBar()`, manteniendo la `SnackBarAction` "Generar email" existente.
- [x] 1.2 Cambiar `duration` del `SnackBar` a un valor efectivamente indefinido (ej. `Duration(days: 1)`) para que no se auto-oculte por timeout.
- [x] 1.3 En `_submit`, llamar `ScaffoldMessenger.of(context).hideCurrentSnackBar()` antes de invocar `context.read<AddSourceCubit>().addSource(...)`.
- [x] 1.4 En `dispose()` de `_AddSourceViewState`, llamar `ScaffoldMessenger.of(context).hideCurrentSnackBar()` antes de `super.dispose()`.

## 2. Tests

- [x] 2.1 Widget test: al recibir `AddSourceFeedDiscoveryFailed`, se muestra el `SnackBar` con el ícono de cerrar visible, y al tocarlo el `SnackBar` desaparece.
- [x] 2.2 Widget test: con el `SnackBar` de error visible, al tocar "Agregar" nuevamente el `SnackBar` previo se oculta.
- [x] 2.3 Widget test: al hacer pop/salir de `AddSourceScreen` con el `SnackBar` de error visible, no queda un `SnackBar` visible tras la navegación.

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` sin warnings.
- [x] 3.2 Correr `flutter test` y confirmar que toda la suite pasa.
