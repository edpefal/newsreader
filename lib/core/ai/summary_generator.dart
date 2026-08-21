import 'package:newsreader/core/errors/app_error_code.dart';

/// Título, extracto y fuente de un artículo, listos para incluir en el
/// prompt de resumen. Se incluye [sourceName] para que el backend pueda
/// agrupar y organizar el resumen por fuente en una sola llamada.
typedef ArticleExcerpt = ({String title, String excerpt, String sourceName});

abstract class SummaryGenerator {
  /// Genera, en una sola invocación, un texto de resumen organizado por
  /// fuente a partir de los artículos dados.
  /// Lanza [SummaryGenerationException] si la generación falla (red, backend
  /// caído, respuesta inválida, etc).
  Future<String> summarize(List<ArticleExcerpt> articles);
}

class SummaryGenerationException implements Exception {
  final AppErrorCode code;

  const SummaryGenerationException(this.code);

  @override
  String toString() => 'SummaryGenerationException: $code';
}
