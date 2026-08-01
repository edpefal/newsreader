## Why

La app crashea con `type 'Null' is not a subtype of type 'Article' in type cast` al volver del background: las rutas `/article/:id`, `/sources/:id` y `/summaries/:date` leen el objeto completo (`Article`/`NewsSource`/`DailySummary`) desde `state.extra` de go_router, que solo vive en memoria. Cuando Android mata el proceso y lo restaura (o el engine reconstruye el árbol de rutas), go_router recrea la ruta a partir de la URL pero `extra` es `null` — y el cast falla, tirando abajo toda la app con una pantalla en blanco/crash en vez de degradar con gracia.

## What Changes

- Las tres rutas dejan de depender exclusivamente de `state.extra`: si `extra` no es del tipo esperado (`null` u otro), la ruta resuelve el dato completo consultando el repositorio correspondiente por su id/fecha (ya presente en la URL), mostrando un loading breve mientras se resuelve.
- Si el id/fecha de la URL no corresponde a ningún registro local (dato borrado, o corrupción), la ruta redirige a `/` en vez de crashear.
- Se agrega `SourceRepository.getSourceById(String id)` y `SummaryRepository.getById(String id)` (hoy no existen — solo hay `getSources()`/`getAll()` completos). `ArticleRepository.getArticleById` ya existe y se reusa tal cual.
- Se agrega un widget compartido en `core/navigation/` que encapsula el patrón "usar `extra` si está, si no resolver por id de forma async, si no se encuentra reencaminar" para las tres rutas, en vez de triplicar la lógica en `router.dart`.

## Capabilities

### New Capabilities
- `route-state-recovery`: el sistema recupera el estado necesario para las pantallas de detalle (artículo, fuente, resumen diario) a partir del identificador en la URL cuando el estado de navegación en memoria (`extra`) no está disponible, en vez de crashear.

### Modified Capabilities
(ninguna — no existe hoy una capability sobre navegación/routing cuyos requirements cambien; esto es una capability nueva)

## Impact

- `lib/presentation/app/router.dart`: los tres `GoRoute` builders (`/article/:id`, `/sources/:id`, `/summaries/:date`) pasan a usar el widget de resolución compartido.
- `lib/core/navigation/` (nuevo): widget genérico de resolución por id con fallback a `extra`.
- `lib/core/domain/repositories/source_repository.dart` y su implementación: nuevo método `getSourceById`.
- `lib/core/domain/repositories/summary_repository.dart` y su implementación: nuevo método `getById`.
- Sin cambios de esquema en Hive/Supabase ni en las firmas de `ReaderScreen`, `SourceDetailScreen` ni `SummaryDetailScreen` (siguen recibiendo el objeto ya resuelto).
