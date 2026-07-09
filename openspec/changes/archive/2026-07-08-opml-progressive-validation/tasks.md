## 1. Mover SourcesCubit al root del árbol de widgets

- [x] 1.1 En `App` (o en el builder del `StatefulShellRoute` en el router), agregar `SourcesCubit` al `MultiBlocProvider` del root, usando `getIt<GetSources>()`, `getIt<UpdateSourceName>()` y `getIt<DeleteSource>()`
- [x] 1.2 En `SourcesScreen`, eliminar el `BlocProvider(create: ...)` que crea el cubit y reemplazarlo por `BlocProvider.value` tomando el cubit del árbol, o simplemente usar el cubit heredado sin proveedor adicional
- [x] 1.3 Llamar `loadSources()` en el cubit root una vez en la inicialización (equivalente a lo que hacía el `create` anterior)

## 2. Recargar Fuentes al tocar el tab

- [x] 2.1 En `_ScaffoldWithNavBar.onDestinationSelected`, agregar `if (index == 3) context.read<SourcesCubit>().loadSources()` antes de `navigationShell.goBranch(...)`

## 3. Validación concurrente con callback progresivo en `ImportOpml`

- [x] 3.1 Cambiar la firma de `ImportOpml.validateFeeds()` de `Future<List<OpmlFeedValidation>>` a `Future<void>` con parámetro `{required void Function(OpmlFeedValidation) onResult}`
- [x] 3.2 En la implementación, reemplazar los batches secuenciales por `Future.wait(urls.map((url) async { final r = await _validateSingle(url); onResult(r); }))` 

## 4. Estado progresivo en `ImportOpmlPreview`

- [x] 4.1 Agregar campo `final int pendingCount` a `ImportOpmlPreview` en `import_opml_state.dart`, con `pendingCount == 0` indicando validación completa
- [x] 4.2 Actualizar `ImportOpmlPreview.props` para incluir `pendingCount`
- [x] 4.3 Actualizar `ImportOpmlPreview.copyWith` si existe, o agregar constructor con todos los parámetros

## 5. Lógica progresiva en `ImportOpmlCubit`

- [x] 5.1 Reescribir `ImportOpmlCubit.loadPreview()` para acumular resultados e ir emitiendo `ImportOpmlPreview` con `pendingCount` decreciente en cada callback de `validateFeeds`
- [x] 5.2 Emitir el primer `ImportOpmlPreview` tan pronto como llegue el primer resultado (no esperar a tenerlos todos)

## 6. UI progresiva en `ImportOpmlScreen`

- [x] 6.1 En `_PreviewView`, mostrar un indicador de progreso (texto "Validando N feeds más…" o `LinearProgressIndicator`) cuando `state.pendingCount > 0`
- [x] 6.2 Habilitar el botón "Importar (N)" tan pronto como haya al menos un feed seleccionado, incluso si `pendingCount > 0`
- [x] 6.3 Ocultar el indicador de progreso cuando `state.pendingCount == 0`

## 7. Tests

- [x] 7.1 Actualizar los tests unitarios de `ImportOpml.validateFeeds()` para usar el nuevo parámetro `onResult` en lugar del valor de retorno
- [x] 7.2 Actualizar los tests de `ImportOpmlCubit` para verificar que se emiten estados `ImportOpmlPreview` intermedios con `pendingCount > 0`
- [x] 7.3 Actualizar los tests de `SourcesScreen` / `_ScaffoldWithNavBar` si los hay, para verificar que `loadSources()` se llama al tocar el tab de Fuentes
- [x] 7.4 Correr `flutter test` y resolver cualquier fallo

## 8. Verificación

- [x] 8.1 Correr `flutter analyze` y resolver warnings
- [ ] 8.2 Probar en simulador: importar OPML con ≥10 feeds y verificar que los resultados aparecen progresivamente
- [ ] 8.3 Probar en simulador: agregar una fuente, navegar a otro tab, tocar tab Fuentes → la nueva fuente aparece
