/// Dirección de email y feed URL generados para un newsletter sin RSS.
typedef GeneratedEmailFeed = ({String email, String feedUrl});

abstract class EmailFeedGenerator {
  /// Genera una dirección de email única y su feed RSS correspondiente.
  /// [label] es un nombre opcional para identificar el newsletter.
  /// Lanza [EmailFeedGenerationException] si la generación falla (red,
  /// backend caído, límite alcanzado, respuesta inválida, etc).
  Future<GeneratedEmailFeed> generate({String? label});
}

class EmailFeedGenerationException implements Exception {
  final String message;

  const EmailFeedGenerationException(this.message);

  @override
  String toString() => 'EmailFeedGenerationException: $message';
}
