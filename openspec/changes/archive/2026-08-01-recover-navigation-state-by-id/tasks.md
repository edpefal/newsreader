## 1. Repositorios: lookup por identificador

- [x] 1.1 Agregar `Future<NewsSource?> getSourceById(String id)` a `SourceRepository` y su implementación en `SourceRepositoryImpl` (filtrando `getSources()`).
- [x] 1.2 Agregar `Future<DailySummary?> getById(String id)` a `SummaryRepository` y su implementación en `SummaryRepositoryImpl` (filtrando `getAll()`).

## 2. Widget compartido de resolución

- [x] 2.1 Crear `lib/core/navigation/route_extra_resolver.dart` con `RouteExtraResolver<T>`: si `extra is T`, construye de inmediato; si no, resuelve con `FutureBuilder<T?>` mostrando un loading (`Scaffold` + `CircularProgressIndicator`) y, si el resultado es `null`, invoca `onNotFound`.

## 3. Router

- [x] 3.1 Actualizar el builder de `/article/:id` en `router.dart` para usar `RouteExtraResolver<Article>` con `resolve: () => getIt<ArticleRepository>().getArticleById(id)` y `onNotFound: () => context.go('/')`.
- [x] 3.2 Actualizar el builder de `/sources/:id` para usar `RouteExtraResolver<NewsSource>` con `resolve: () => getIt<SourceRepository>().getSourceById(id)`.
- [x] 3.3 Actualizar el builder de `/summaries/:date` para usar `RouteExtraResolver<DailySummary>` con `resolve: () => getIt<SummaryRepository>().getById(id)` (el path param sigue llamándose `:date` pero el valor pasado es el `id` del resumen — ver nota en proposal.md).

## 4. Tests

- [x] 4.1 Test unitario de `SourceRepositoryImpl.getSourceById`: encuentra por id, devuelve `null` si no existe.
- [x] 4.2 Test unitario de `SummaryRepositoryImpl.getById`: encuentra por id, devuelve `null` si no existe.
- [x] 4.3 Test de widget de `RouteExtraResolver`: con `extra` del tipo esperado, construye directo sin mostrar loading.
- [x] 4.4 Test de widget de `RouteExtraResolver`: con `extra` nulo, muestra loading y luego el contenido resuelto por `resolve()`.
- [x] 4.5 Test de widget de `RouteExtraResolver`: si `resolve()` devuelve `null`, invoca `onNotFound` en vez de crashear.

## 5. Verificación final

- [x] 5.1 Correr `flutter analyze` sin warnings.
- [x] 5.2 Correr `flutter test` completo.
- [x] 5.3 Prueba manual: abrir un artículo, forzar el proceso a background y matarlo (o simular restauración), reabrir la app y confirmar que no crashea. (Verificado forzando `extra: null` directamente en el código en vivo — el proceso-kill no reproduce el escenario porque la app no tiene `restorationScopeId` ni deep links configurados. Resultado: el artículo abrió normal, sin crash.)
