## 1. Eliminar el modo reader de ReaderScreen

- [x] 1.1 En `lib/features/reader/presentation/screens/reader_screen.dart`: eliminar el `IconButton` de modo reader del `AppBar` (ícono `chrome_reader_mode`/`chrome_reader_mode_outlined`, tooltip "Modo Reader"/"Vista original").
- [x] 1.2 Eliminar el campo `_isReaderMode` y la rama correspondiente en `_buildContent`.
- [x] 1.3 Eliminar los métodos `_buildReaderContent` y `_stripHtml` (quedan sin ningún caller).
- [x] 1.4 Eliminar la constante `AppConstants.settingsReaderModeKey` en `lib/core/constants/app_constants.dart`.

## 2. Actualizar tests y documentación

- [x] 2.1 Eliminar los 4 tests de modo reader en `test/widget/features/reader/reader_screen_test.dart` ("muestra botón de Modo Reader en el AppBar", "activar Modo Reader oculta HtmlWidget y muestra texto plano", "desactivar Modo Reader vuelve a mostrar HtmlWidget", "Modo Reader con excerpt (sin contentHtml) muestra el excerpt").
- [x] 2.2 Actualizar el bullet de "Lector" en la sección de Características de `README.md`, quitando la mención a "modo reader (texto plano)".

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` y resolver cualquier warning.
- [x] 3.2 Correr `flutter test` y confirmar que todo pasa. 194/194 tests pasan (198 - 4 tests de modo reader eliminados).
- [x] 3.3 Probar manualmente en el emulador: abrir un artículo, confirmar que el `AppBar` solo tiene favorito y "Ver en navegador", y que el contenido HTML se ve igual que antes. Verificado manualmente por el usuario.
