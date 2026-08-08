## Why

`/article/:id/web` (la pantalla de WebView del artículo) hace `state.extra as Article` sin ningún fallback (`lib/presentation/app/router.dart:100-103`). Cuando el estado de navegación en memoria no trae el `extra` (ej. el proceso de la app fue recreado en background), el cast falla con `type 'Null' is not a subtype of type 'Article' in type cast` y la app crashea — reproducido en dispositivo real al tocar "Ver en navegador"/el aviso de contenido truncado tras la app pasar un rato en background. Las rutas `/article/:id`, `/sources/:id` y `/summaries/:date` ya están protegidas contra este mismo problema (capability `route-state-recovery`, vía `RouteExtraResolver`), pero la ruta hija `/article/:id/web` quedó afuera de esa protección.

## What Changes

- `/article/:id/web` pasa a usar `RouteExtraResolver<Article>`, igual que su ruta padre `/article/:id`, resolviendo el artículo por id (`ArticleRepository.getArticleById`) cuando `extra` no está disponible o no es del tipo esperado.
- Mismo comportamiento ya normado para las otras rutas de detalle: indicador de carga mientras se resuelve, y redirección al Inbox si el id no corresponde a ningún artículo existente.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `route-state-recovery`: se agrega `/article/:id/web` a la lista de rutas cubiertas por la recuperación de datos por identificador.

## Impact

- `lib/presentation/app/router.dart`: la ruta hija `web` bajo `/article/:id` pasa a envolver `WebviewFlutterArticleWebView` con `RouteExtraResolver<Article>`, igual patrón que la ruta padre.
- Tests de routing (si existen) o nuevo test a agregar para cubrir el caso de restauración sin `extra` en esta ruta específica.
