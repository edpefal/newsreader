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
