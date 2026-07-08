## 1. Implementación

- [x] 1.1 En `ImportOpmlScreen`, en el `BlocListener` que maneja `ImportOpmlDone`, agregar `context.read<InboxCubit>().syncAndReload()` antes de `Navigator.of(context).pop(true)`
- [x] 1.2 Agregar el import de `InboxCubit` en `import_opml_screen.dart`

## 2. Tests

- [x] 2.1 En el widget test de `ImportOpmlScreen`, verificar que cuando el estado es `ImportOpmlDone` se llama a `InboxCubit.syncAndReload()`
- [x] 2.2 Correr `flutter test` y resolver cualquier fallo

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` y resolver warnings
- [x] 3.2 Probar en simulador: importar OPML → regresar al home → verificar que los artículos aparecen sin pull-to-refresh
