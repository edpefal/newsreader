/// Nivel de severidad de un mensaje reportado a través de
/// [TelemetryClient.captureMessage].
enum TelemetryLevel { debug, info, warning, error, fatal }

/// Abstracción sobre los proveedores de telemetría (hoy Sentry para errores
/// y PostHog para eventos de producto). Ningún archivo fuera de
/// `core/observability/` y `core/di/injection.dart` debe importar el
/// paquete de un proveedor concreto directamente.
abstract class TelemetryClient {
  /// Reporta una excepción capturada (ya sea no manejada o atrapada
  /// intencionalmente por el código). [context] nunca debe incluir PII
  /// (email, contenido de artículos). Va a Sentry.
  void captureException(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
  });

  /// Reporta un mensaje sin una excepción asociada. Va a Sentry.
  void captureMessage(String message, {TelemetryLevel level = TelemetryLevel.info});

  /// Deja una miga de pan de bajo nivel para dar contexto a futuros reportes
  /// de error. Va a Sentry.
  void addBreadcrumb(String message, {String? category, Map<String, Object?>? data});

  /// Registra un evento de producto (ver capability `product-analytics`).
  /// Va a PostHog.
  void trackEvent(String name, {Map<String, Object?>? properties});

  /// Asocia (o desasocia, con `null`) los reportes y eventos siguientes al
  /// usuario con sesión activa, tanto en Sentry como en PostHog. Nunca
  /// recibe el email del usuario, solo su id.
  void setUserId(String? userId);
}
