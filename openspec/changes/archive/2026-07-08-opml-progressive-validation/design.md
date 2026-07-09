## Context

`ImportOpml.validateFeeds()` procesa feeds en batches secuenciales de 5. Cada batch corre `Future.wait` sobre 5 requests HTTP, pero los batches no empiezan hasta que el anterior termina. Con 50 feeds y un timeout de 10s/feed, el peor caso es ~100s de spinner.

`ImportOpmlCubit.loadPreview()` llama `validateFeeds()` y solo emite `ImportOpmlPreview` cuando obtiene la lista completa. El estado intermedio `ImportOpmlValidating` solo muestra "Validando feeds…".

Separado: `_ScaffoldWithNavBar.onDestinationSelected` recarga `FavoritesCubit` (index 1) y `ArchiveCubit` (index 2) al tocar sus tabs, pero no recarga `SourcesCubit` al tocar el tab de Fuentes (index 3).

## Goals / Non-Goals

**Goals:**
- Mostrar resultados de validación de feeds tan pronto como cada uno termina, sin esperar al batch completo
- Al tocar el tab Fuentes, recargar la lista de fuentes

**Non-Goals:**
- Cambiar el flujo de importación después de la validación (confirmación, progreso de import)
- Limitar la concurrencia de validaciones (se corre todo concurrente — en móvil el sistema ya lo limita con conexiones HTTP)
- Mostrar progreso por feed durante la importación (solo durante validación)

## Decisions

### 1. Validación concurrente sin batches, con callback progresivo

**Decisión:** Reemplazar los batches secuenciales por un único `Future.wait` sobre todos los feeds, con un callback `onResult` que se llama al completar cada feed individual.

```dart
Future<void> validateFeeds(
  List<String> urls, {
  required void Function(OpmlFeedValidation result) onResult,
}) async {
  await Future.wait(urls.map((url) async {
    final result = await _validateSingle(url);
    onResult(result);
  }));
}
```

**Alternativa descartada — Stream:** Devolver un `Stream<OpmlFeedValidation>` es más idiomático en Dart pero requiere cambios en el contrato de `ImportOpml` (use case), agrega complejidad en los tests (StreamController), y el callback es suficiente para el caso de uso.

**Alternativa descartada — mantener batches pero emitir por batch:** Reduce la latencia a 1 batch (~10s para 5 feeds), pero no da resultados individuales. La UX sigue siendo saltos, no progresión fluida.

### 2. `ImportOpmlPreview` unifica el estado parcial y el completo

**Decisión:** Agregar un campo `pendingCount` a `ImportOpmlPreview` para representar cuántos feeds quedan por validar. Cuando `pendingCount == 0` la validación terminó.

```dart
class ImportOpmlPreview extends ImportOpmlState {
  final List<OpmlFeedItem> feeds;
  final int pendingCount;   // 0 = validación completa
  ...
}
```

`ImportOpmlCubit.loadPreview()` emite `ImportOpmlPreview` incrementalmente:

```dart
final items = <OpmlFeedItem>[];
int pending = urls.length;

await _importOpml.validateFeeds(urls, onResult: (v) {
  items.add(...);
  pending--;
  emit(ImportOpmlPreview(items.toList(), pendingCount: pending));
});
```

**Alternativa descartada — estado `ImportOpmlValidatingWithPartialResults`:** Agrega un estado más sin necesidad; `pendingCount` en `ImportOpmlPreview` es suficiente y más simple.

### 3. `ImportOpmlPreview` en `ImportOpmlScreen` muestra indicador cuando `pendingCount > 0`

**Decisión:** En `_PreviewView`, si `state.pendingCount > 0`, mostrar un `LinearProgressIndicator` en el tope de la lista o un texto "Validando N feeds más…" bajo la lista. El botón "Importar" se habilita tan pronto como hay algún feed seleccionado, aunque aún haya feeds pendientes.

**Alternativa descartada — bloquear botón hasta que `pendingCount == 0`:** El usuario podría querer importar solo los feeds que ya validaron. Bloquear el botón sería innecesariamente restrictivo.

### 4. Recarga de SourcesCubit al tocar el tab de Fuentes

**Decisión:** En `_ScaffoldWithNavBar.onDestinationSelected`, agregar `if (index == 3) context.read<SourcesCubit>().loadSources()`.

Esta es la misma solución que ya existe para Favoritos (index 1) y Leídos (index 2). `SourcesCubit` está provisto desde el root del árbol via `get_it`, por lo que es accesible con `context.read<SourcesCubit>()` en `_ScaffoldWithNavBar`.

**Problema:** `SourcesCubit` actualmente se crea dentro del `BlocProvider.create` de `SourcesScreen`, no en el root. Por lo tanto NO es accesible desde `_ScaffoldWithNavBar`.

**Solución:** Mover `SourcesCubit` al `MultiBlocProvider` del root (en `App` o en el builder del `StatefulShellRoute`), igual que `InboxCubit`, `FavoritesCubit` y `ArchiveCubit`. `SourcesScreen` pasa a usar `BlocProvider.value` (o a no proveer el cubit, ya que lo hereda del árbol).

## Risks / Trade-offs

- **[Trade-off] Validaciones concurrentes sin límite:** En vez de 5 a la vez, ahora se abren N conexiones simultáneamente. En la práctica, el sistema operativo limita las conexiones HTTP concurrentes, y el package `http` usa el stack de red nativo. Para N razonable (≤ 100 feeds), esto es aceptable en móvil.

- **[Riesgo] Orden de aparición no determinista:** Los feeds aparecen en el orden en que sus requests terminan, no el orden del OPML original. Si el usuario espera el orden original, puede ser confuso. **Mitigación:** Aceptable — la lista final permite ordenar/filtrar, y la naturaleza progresiva es más valiosa que el orden determinista.

- **[Complejidad] Mover SourcesCubit al root:** Requiere tocar `App`, el router, y `SourcesScreen`. Es un refactor pequeño pero amplía el scope levemente.

- **[Tests] Cambio de firma de `validateFeeds`:** Los tests existentes de `ImportOpml` y `ImportOpmlCubit` necesitan adaptarse al patrón de callback. Es trabajo esperado.
