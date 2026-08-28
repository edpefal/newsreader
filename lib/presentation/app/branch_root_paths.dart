/// Paths raíz de las 5 branches de `StatefulShellRoute.indexedStack`
/// definidas en `router.dart`. Sirve para que `AdaptiveShell` distinga, en
/// modo compact, si la ruta activa es la lista de una tab (chrome del shell
/// visible) o una pantalla de detalle empujada a pantalla completa (chrome
/// oculto) -- ver design.md del change `fix-detail-view-appbar-regression`.
const branchRootPaths = <String>['/', '/favorites', '/archive', '/sources', '/summaries'];
