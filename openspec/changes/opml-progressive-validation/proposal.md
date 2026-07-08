## Why

Al importar un archivo OPML con muchos feeds, la pantalla de validación muestra un spinner sin feedback durante decenas de segundos (hasta 100s para 50 feeds), porque la validación es secuencial por batches de 5. Además, al regresar al tab de Fuentes después de importar, la lista no se actualiza — las fuentes recién importadas no aparecen sin reiniciar la app.

## What Changes

- La validación de feeds en OPML pasa de batches secuenciales a carga progresiva: cada feed aparece en la lista tan pronto como termina de validarse, en vez de esperar que todo el batch complete.
- El `ImportOpmlCubit` emite estados intermedios con la lista parcial mientras validan los feeds restantes.
- Al hacer tap en el tab de Fuentes, la lista de fuentes se recarga automáticamente (igual que Favoritos y Leídos).

## Capabilities

### New Capabilities

- `opml-progressive-validation`: Validación progresiva de feeds OPML con feedback incremental mientras se resuelven

### Modified Capabilities

- `opml-import`: El flujo de validación ahora muestra resultados progresivos en vez de esperar a que todos los feeds terminen
- `source-management`: Al navegar al tab de Fuentes se recarga la lista automáticamente

## Impact

- `ImportOpml.validateFeeds()` — cambia la firma para devolver un `Stream` (o callback) en lugar de `Future<List>`
- `ImportOpmlCubit.loadPreview()` — consume el stream progresivo y emite `ImportOpmlPreview` con lista parcial
- `ImportOpmlState` — `ImportOpmlPreview` pasa a representar tanto el estado "cargando con resultados parciales" como el "completo"
- `_ScaffoldWithNavBar.onDestinationSelected` — agrega recarga de `SourcesCubit` cuando `index == 3`
- Tests de `ImportOpmlCubit` y `ImportOpml` necesitan actualizarse
