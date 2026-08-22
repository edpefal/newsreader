/// Identifica cada escenario de error conocido de la app. Las excepciones y
/// estados que antes cargaban un `String message` hardcodeado en español
/// pasan a cargar uno de estos valores; el texto se resuelve recién en la
/// capa de presentación vía `AppErrorCodeL10n.localize`, para que respete
/// el idioma activo de la app.
enum AppErrorCode {
  /// Sin conexión a internet.
  network,

  /// La solicitud tardó demasiado.
  timeout,

  /// La URL ingresada no resultó ser un feed RSS válido.
  invalidFeedUrl,

  /// El archivo no es un OPML válido.
  invalidOpmlFile,

  /// La fuente ya estaba agregada.
  duplicateSource,

  /// Recurso no encontrado. Sin call sites hoy; se mantiene por
  /// completitud del enum ([NotFoundException] no se lanza actualmente).
  notFound,

  /// No se pudo detectar el feed automáticamente a partir de la URL.
  feedDiscoveryFailed,

  /// La operación requiere una sesión activa y no la hay.
  noActiveSession,

  /// No se pudo eliminar la cuenta.
  accountDeletionFailed,

  /// El proveedor de login (Google) no devolvió un token válido.
  googleTokenMissing,

  /// El proveedor de login (Apple) no devolvió un token válido.
  appleTokenMissing,

  /// Error del proveedor de login nativo (ej. Sign in with Apple) con
  /// detalle que no podemos traducir nosotros.
  authProviderError,

  /// El campo de URL para agregar una fuente está vacío.
  emptyUrl,

  /// El archivo OPML no contiene ningún feed.
  opmlNoFeedsFound,

  /// Un feed individual dentro de un archivo OPML no pudo validarse.
  opmlFeedValidationFailed,

  /// No hay artículos nuevos para generar el resumen del día.
  noArticlesToday,

  /// Fallo genérico al completar una operación contra el backend
  /// (generación de resumen, generación de dirección de email).
  generationFailed,

  /// Se alcanzó el presupuesto diario de palabras de IA (ver capability
  /// `ai-usage-budget`); distinto de un fallo genérico de generación.
  aiUsageLimitReached,

  /// Cualquier error no anticipado por los demás códigos.
  unknown,
}
