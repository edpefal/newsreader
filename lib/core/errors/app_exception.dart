sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Sin conexión a internet']);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'La solicitud tardó demasiado']);
}

class ParseException extends AppException {
  const ParseException([super.message = 'No se encontró un feed válido en esta URL']);
}

class DuplicateSourceException extends AppException {
  const DuplicateSourceException([super.message = 'Ya estás suscrito a esta fuente']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'No encontrado']);
}

class FeedDiscoveryException extends AppException {
  const FeedDiscoveryException([
    super.message =
        'No pudimos detectar el feed automáticamente. Pega la URL exacta '
            'del feed RSS (por ejemplo, que termine en /feed o .xml).',
  ]);
}
