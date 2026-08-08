## 1. Router: `/article/:id/web` con `RouteExtraResolver`

- [x] 1.1 En `lib/presentation/app/router.dart`, reemplazar el `builder` de la ruta hija `web` (bajo `/article/:id`) para envolver `WebviewFlutterArticleWebView` con `RouteExtraResolver<Article>`, resolviendo por `getIt<ArticleRepository>().getArticleById(state.pathParameters['id']!)` y con `onNotFound: (context) => context.go('/')`, igual patrón que la ruta padre `/article/:id`.

## 2. Verificación

- [x] 2.1 Correr `flutter analyze` sin warnings nuevos.
- [x] 2.2 Correr `flutter test test/widget/core/navigation/` (ruta corregida — el test vive en `test/widget/`, no `test/unit/`) y confirmar que `RouteExtraResolver` sigue pasando (sin cambios ahí, solo para confirmar que no se rompió nada).
- [ ] 2.3 Probar manualmente en la app: abrir un artículo, mandar la app a background el tiempo suficiente para que Android mate el proceso (o forzar el cierre desde el selector de apps), reabrir, y navegar al WebView del artículo — confirmar que no crashea.
