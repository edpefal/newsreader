## Context

Ver `proposal.md` para la motivación (crash reproducido en dispositivo real). `RouteExtraResolver<T>` (`lib/core/navigation/route_extra_resolver.dart`) ya existe y ya está probado (`test/unit/core/navigation/route_extra_resolver_test.dart`): si `extra` es del tipo esperado lo usa directo, si no, llama `resolve()` (mostrando un `CircularProgressIndicator` mientras tanto) y si `resolve()` devuelve `null`, invoca `onNotFound`. Las rutas `/article/:id`, `/sources/:id` y `/summaries/:date` ya lo usan. `/article/:id/web` es la única ruta de detalle que no lo usa — hace `state.extra as Article` directo.

## Goals / Non-Goals

**Goals:**
- Eliminar el crash, con el mismo patrón ya usado (y ya probado) en el resto de las rutas de detalle.

**Non-Goals:**
- No se agrega un test de integración nuevo para `router.dart` en sí — hoy no existe ningún test que ejercite el árbol de rutas completo (las otras rutas con `RouteExtraResolver` tampoco lo tienen), y armar ese harness sería un cambio de alcance mucho mayor al de este fix puntual. La cobertura queda en `RouteExtraResolver` (ya probado genéricamente) más verificación manual.

## Decisions

### 1. Mismo patrón `RouteExtraResolver<Article>` que la ruta padre, reusando `ArticleRepository.getArticleById`

No hay alternativa real a considerar acá: es exactamente el mismo problema que ya resolvieron las otras tres rutas, con la misma herramienta ya disponible. Cualquier otro enfoque (ej. un cast defensivo con valor por defecto, o simplemente `context.go('/')` si `extra` es nulo) sería inconsistente con el patrón ya establecido y perdería la recuperación real del dato — el usuario terminaría en el Inbox en vez de ver el WebView que estaba buscando.

## Risks / Trade-offs

- **[Trade-off] Un fetch adicional a `ArticleRepository.getArticleById` en el caso de restauración sin estado** → Aceptado: mismo costo que ya pagan las otras rutas de detalle en el mismo escenario, y solo ocurre cuando el estado de navegación ya se perdió (caso infrecuente), no en la navegación normal desde la app.
