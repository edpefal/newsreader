import 'package:flutter/widgets.dart';

/// Desde dónde se abrió el paywall. Su [analyticsName] es el valor de la
/// propiedad `trigger` de `paywall_viewed`.
enum PaywallTrigger {
  settings('settings'),
  articleSummary('article_summary'),
  reader('reader');

  final String analyticsName;

  const PaywallTrigger(this.analyticsName);
}

/// Muestra el paywall de suscripción de la app. Lo reciben por constructor los
/// features que lo abren (Ajustes, resumen de un artículo, lector) en vez de
/// importar la pantalla, porque un feature no importa de otro; la
/// implementación vive a nivel de app (`presentation/paywall/`).
abstract class PaywallLauncher {
  /// Presenta el paywall y espera a que se cierre. Devuelve `true` si el
  /// usuario quedó suscrito (compró o restauró), `false` si lo cerró sin
  /// suscribirse.
  Future<bool> show(BuildContext context, {required PaywallTrigger trigger});
}
