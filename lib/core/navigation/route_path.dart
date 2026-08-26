import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/utils/window_size_class.dart';

/// Concatena un segmento de ruta relativo a [basePath], evitando la doble
/// barra cuando [basePath] es la raíz (`/`). Usado para navegar a rutas
/// anidadas (ej. el lector de artículo) sin hardcodear a qué branch
/// pertenece la pantalla actual.
String joinRoutePath(String basePath, String segment) {
  return basePath == '/' ? '/$segment' : '$basePath/$segment';
}

/// Abre una ruta de detalle (ej. el lector de artículo) desde una pantalla
/// de lista que permanece visible en modo split (ver `AdaptiveListDetailScaffold`).
///
/// En modo compact usa `push` y espera a que el usuario vuelva (back) para
/// llamar [onOpened] -- igual que el comportamiento de push a pantalla
/// completa de siempre.
///
/// En modo expanded la lista nunca desaparece, así que seleccionar un
/// segundo ítem sin haber "vuelto" del primero pushearía uno encima del
/// otro indefinidamente (además de nunca disparar [onOpened], que dependía
/// de esperar el pop). Por eso ahí se usa `go` -- reemplaza la ruta activa
/// del panel derecho en vez de apilar -- y se llama [onOpened] de
/// inmediato, sin esperar ningún pop que en este modo no va a ocurrir.
void openDetailRoute({
  required BuildContext context,
  required String path,
  required Object? extra,
  required VoidCallback onOpened,
}) {
  if (context.windowSizeClass == WindowSizeClass.expanded) {
    context.go(path, extra: extra);
    onOpened();
    return;
  }
  context.push(path, extra: extra).then((_) {
    if (context.mounted) onOpened();
  });
}
