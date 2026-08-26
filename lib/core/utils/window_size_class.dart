import 'package:flutter/widgets.dart';

/// Umbral de ancho ("expanded" de Material 3) a partir del cual la app usa
/// `NavigationRail` y el layout de dos paneles en vez de `NavigationDrawer`
/// y el push de pantalla completa.
const double kExpandedWidthBreakpoint = 840;

enum WindowSizeClass { compact, expanded }

extension WindowSizeClassContext on BuildContext {
  WindowSizeClass get windowSizeClass {
    final width = MediaQuery.sizeOf(this).width;
    return width >= kExpandedWidthBreakpoint
        ? WindowSizeClass.expanded
        : WindowSizeClass.compact;
  }
}
