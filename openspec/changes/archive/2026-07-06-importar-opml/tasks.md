## 1. Dependencias y configuración

- [x] 1.1 Agregar `file_picker` y `xml` a `pubspec.yaml` y correr `flutter pub get`
- [x] 1.2 Verificar que `flutter analyze` pasa sin warnings tras agregar dependencias

## 2. Abstracción OPMLParser en core

- [x] 2.1 Crear `lib/core/opml/opml_parser.dart` con interfaz abstracta `OPMLParser` que expone `List<String> parse(String xmlContent)`
- [x] 2.2 Crear `lib/core/opml/xml_opml_parser.dart` con `XmlOpmlParser implements OPMLParser` usando el paquete `xml`, extrayendo todos los `xmlUrl` de outlines anidados a cualquier nivel
- [x] 2.3 Manejar XML inválido lanzando `ParseException` desde `XmlOpmlParser`

## 3. Use case ImportOpml

- [x] 3.1 Crear `lib/features/sources/domain/usecases/import_opml.dart` con clase `ImportOpml` que recibe `OPMLParser` y `AddSource`
- [x] 3.2 Implementar `ImportOpmlResult` con campos `imported`, `skippedDuplicates` y `failed`
- [x] 3.3 Implementar `execute(String xmlContent)`: parsear OPML, validar feeds en paralelo con `Future.wait()`, clasificar resultados, retornar `ImportOpmlResult`
- [x] 3.4 Capturar `DuplicateSourceException` → `skippedDuplicates`; otras excepciones → `failed`

## 4. Estado y Cubit de ImportOpml

- [x] 4.1 Crear `lib/features/sources/presentation/cubit/import_opml_state.dart` con estados: `ImportOpmlInitial`, `ImportOpmlValidating`, `ImportOpmlPreview` (con lista de `OpmlFeedItem`), `ImportOpmlImporting`, `ImportOpmlDone`, `ImportOpmlError`
- [x] 4.2 Definir `OpmlFeedItem` con campos: `url`, `name`, `iconUrl`, `status` (enum: `valid`, `duplicate`, `error`), `errorMessage`, `selected`
- [x] 4.3 Crear `lib/features/sources/presentation/cubit/import_opml_cubit.dart` con métodos `loadPreview(String xmlContent)` y `toggleSelection(String url)` y `confirmImport()`
- [x] 4.4 Asegurar que todos los estados extienden `Equatable`

## 5. Pantalla ImportOpmlScreen

- [x] 5.1 Crear `lib/features/sources/presentation/screens/import_opml_screen.dart`
- [x] 5.2 En estado `ImportOpmlValidating`: mostrar `CircularProgressIndicator` con texto "Validando feeds…"
- [x] 5.3 En estado `ImportOpmlPreview`: mostrar lista con un `CheckboxListTile` por feed válido, `ListTile` deshabilitado con etiqueta "Ya suscrito" para duplicados, y `ListTile` con icono de error para feeds fallidos
- [x] 5.4 Mostrar botón "Importar (N)" habilitado solo cuando hay al menos un feed seleccionado
- [x] 5.5 En estado `ImportOpmlDone`: navegar de regreso y mostrar snackbar con resumen ("N fuentes importadas")
- [x] 5.6 En estado `ImportOpmlError`: mostrar mensaje de error en pantalla (ej. archivo OPML inválido)

## 6. Punto de entrada en AddSourceScreen

- [x] 6.1 Agregar botón secundario `TextButton` "Importar desde OPML" en `AddSourceScreen`, debajo del botón principal "Agregar"
- [x] 6.2 Al pulsar: lanzar `FilePicker.platform.pickFiles(allowedExtensions: ['opml', 'xml'])`, leer el contenido del archivo seleccionado, y navegar a `/sources/import-opml` pasando el contenido XML como `extra`
- [x] 6.3 Si el usuario cancela el picker, no navegar ni mostrar error

## 7. Ruta y DI

- [x] 7.1 Agregar ruta `/sources/import-opml` en `router.dart` que instancia `ImportOpmlScreen` con `ImportOpmlCubit` provisto vía `BlocProvider`, leyendo `state.extra as String`
- [x] 7.2 Registrar `OPMLParser` (implementado por `XmlOpmlParser`) e `ImportOpml` en `injection.dart`

## 8. Tests

- [x] 8.1 Unit test de `XmlOpmlParser`: feeds directos, feeds anidados en carpetas, OPML sin feeds, XML inválido
- [x] 8.2 Unit test de `ImportOpml`: feeds válidos importados, duplicados clasificados, errores clasificados, combinación mixta
- [x] 8.3 Unit test de `ImportOpmlCubit`: `loadPreview` emite estados correctos, `toggleSelection` actualiza selección, `confirmImport` emite `ImportOpmlDone`
- [x] 8.4 Widget test de `ImportOpmlScreen`: estado validating muestra spinner, estado preview muestra lista con checkboxes y tiles deshabilitados, botón habilitado/deshabilitado según selección
- [x] 8.5 Correr `flutter analyze` y resolver cualquier warning

## 9. Verificación final

- [x] 9.1 Probar flujo completo en simulador: abrir AddSourceScreen → pulsar "Importar desde OPML" → seleccionar archivo OPML real → ver preview → importar → verificar fuentes en SourcesScreen
- [x] 9.2 Probar edge cases: archivo con un solo feed ya suscrito, archivo OPML inválido, cancelar el file picker
