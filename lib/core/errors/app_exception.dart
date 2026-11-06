import 'package:newsreader/core/errors/app_error_code.dart';

sealed class AppException implements Exception {
  final AppErrorCode code;
  const AppException(this.code);
}

class NetworkException extends AppException {
  const NetworkException() : super(AppErrorCode.network);
}

class TimeoutException extends AppException {
  const TimeoutException() : super(AppErrorCode.timeout);
}

class ParseException extends AppException {
  const ParseException(super.code);
}

class DuplicateSourceException extends AppException {
  const DuplicateSourceException() : super(AppErrorCode.duplicateSource);
}

class NotFoundException extends AppException {
  const NotFoundException() : super(AppErrorCode.notFound);
}

class FeedDiscoveryException extends AppException {
  const FeedDiscoveryException() : super(AppErrorCode.feedDiscoveryFailed);
}

class AccountDeletionException extends AppException {
  const AccountDeletionException(super.code);
}

/// Error al sincronizar con la nube (Supabase/Postgrest). [code] clasifica
/// la falla (`network`, `timeout`, o `cloudSyncFailed` para cualquier otra)
/// -- ver `SupabaseCloudSyncClient` para la clasificación real.
class CloudSyncException extends AppException {
  final String message;

  const CloudSyncException(
    this.message, [
    AppErrorCode code = AppErrorCode.cloudSyncFailed,
  ]) : super(code);

  @override
  String toString() => 'CloudSyncException: $message';
}

/// Error del proveedor de suscripciones al cargar planes, comprar o restaurar.
/// [reason] es el código del SDK/tienda (sin texto libre del usuario) y solo
/// se usa para telemetría; lo que ve el usuario sale de [code].
class SubscriptionException extends AppException {
  final String reason;

  const SubscriptionException(super.code, this.reason);

  @override
  String toString() => 'SubscriptionException: $code ($reason)';
}
