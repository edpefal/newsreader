/// Nivel de severidad de un mensaje reportado a través de
/// [ObservabilityClient.captureMessage].
enum ObservabilityLevel { debug, info, warning, error, fatal }

/// Abstracción sobre el proveedor de observabilidad (hoy Sentry). Ningún
/// archivo fuera de `core/observability/` y `core/di/injection.dart` debe
/// importar el paquete del proveedor concreto directamente.
abstract class ObservabilityClient {
  /// Reporta una excepción capturada (ya sea no manejada o atrapada
  /// intencionalmente por el código). [context] nunca debe incluir PII
  /// (email, contenido de artículos).
  void captureException(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
  });

  /// Reporta un mensaje sin una excepción asociada.
  void captureMessage(String message, {ObservabilityLevel level = ObservabilityLevel.info});

  /// Deja una miga de pan de bajo nivel para dar contexto a futuros reportes.
  void addBreadcrumb(String message, {String? category, Map<String, Object?>? data});

  /// Registra un evento de producto. Sin call sites en este change.
  void trackEvent(String name, {Map<String, Object?>? properties});

  /// Asocia (o desasocia, con `null`) los reportes siguientes al usuario con
  /// sesión activa. Nunca recibe el email del usuario, solo su id.
  void setUserId(String? userId);
}
