import 'package:flutter/widgets.dart';

import 'package:newsreader/core/observability/telemetry_client.dart';

/// Dispara un evento `screen_view` en cada navegación hacia una nueva
/// pantalla, sin necesidad de instrumentar cada pantalla a mano (ver
/// capability `product-analytics`). go_router nombra cada `Page` construida
/// solo con `builder:` (sin `pageBuilder:`) como `state.name ?? state.path`,
/// así que `route.settings.name` ya es el patrón de la ruta (ej.
/// `article/:id`), no la URL resuelta con el id real -- agrupa bien
/// "pantalla más vista" sin que cada artículo cuente como una pantalla
/// distinta.
///
/// go_router crea un `Navigator` propio por cada `ShellRoute` (una por
/// branch: Inbox/Favoritos/Archivo/Fuentes/Resúmenes), y los observers del
/// `GoRouter` raíz no se propagan a esos Navigators anidados -- por eso esta
/// misma instancia se registra tanto en `GoRouter.observers` como en el
/// `observers` de cada `ShellRoute` (ver `router.dart`).
class ScreenViewObserver extends NavigatorObserver {
  final TelemetryClient _telemetryClient;

  ScreenViewObserver(this._telemetryClient);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackScreen(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _trackScreen(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _trackScreen(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    _telemetryClient.trackEvent('screen_view', properties: {'screen': name});
  }
}
