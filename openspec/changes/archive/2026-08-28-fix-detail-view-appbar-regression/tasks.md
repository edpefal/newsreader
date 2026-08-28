## 1. Shell condicional en compact

- [x] 1.1 Extraer una constante compartida `branchRootPaths` con las 5 raíces de branch a `lib/presentation/app/branch_root_paths.dart` (archivo nuevo, en vez de definirla en `router.dart`, para evitar un import circular entre `router.dart` y `adaptive_shell.dart`), importable desde `adaptive_shell.dart`.
- [x] 1.2 En `AdaptiveShell.build()` (`lib/presentation/app/adaptive_shell.dart`), leer el path actualmente resuelto vía `GoRouterState.of(context).uri.path` y calcular `final isAtBranchRoot = branchRootPaths.contains(currentPath);`.
- [x] 1.3 En la rama `WindowSizeClass.compact` del `build()`, condicionar `appBar` a `isAtBranchRoot ? appBar : null` y `drawer` a `isAtBranchRoot ? _AppNavigationDrawer(...) : null`.
- [x] 1.4 Confirmado: el modo `WindowSizeClass.expanded` no cambia, sigue mostrando `appBar` siempre, sin depender de `isAtBranchRoot`.

## 2. Verificación manual (usuario)

- [x] 2.1 Verificado en simulador por el usuario: al abrir un artículo desde Inbox/Favoritos/Archivo en ancho compact, solo se ve el `AppBar` del lector; al volver atrás reaparece el `AppBar` principal con drawer y buscador.
- [x] 2.2 Verificado en simulador por el usuario para Fuentes y Resúmenes.
- [x] 2.3 Verificado en simulador por el usuario en ancho expanded: el `AppBar` principal sigue mostrándose sin cambios junto al layout de dos paneles.

## 3. Calidad

- [x] 3.1 `flutter analyze` corrido: "No issues found!".
- [x] 3.2 `flutter test` corrido: única falla es `test/widget/core/utils/localized_date_formatter_test.dart` ("muestra hora HH:mm para hoy"), preexistente y no relacionada (reproduce igual en `main` sin este cambio). No existe suite de tests para `AdaptiveShell`/`router.dart` en el repo (no hay precedente de widget test para el shell completo con go_router + 5 branches + DI); agregar esa infraestructura de test excede el alcance de este fix puntual, así que no se agregó cobertura nueva.
