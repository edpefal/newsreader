import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/core/errors/app_error_code.dart';

/// Resultado crudo (sin enriquecer) de resumir un artículo: el texto del
/// resumen más las menciones detectadas por la API de IA -- ver capability
/// `article-summaries`. Interfaz hermana de `SummaryGenerator` (no un
/// método agregado a esa interfaz): el shape de retorno es distinto
/// (resumen + menciones vs. solo texto) y el caso de uso también (un
/// artículo puntual on-demand vs. el inbox completo agrupado por fuente).
typedef ArticleSummaryResult = ({String summary, List<RawMention> mentions});

abstract class ArticleSummaryGenerator {
  /// Genera el resumen de un único artículo (título + contenido) más sus
  /// menciones crudas, en el idioma indicado por [language] (código de 2
  /// letras, ej. "en", "es", "fr"). Lanza [ArticleSummaryGenerationException]
  /// si la generación falla.
  Future<ArticleSummaryResult> summarizeArticle(
    String title,
    String content, {
    required String language,
  });
}

class ArticleSummaryGenerationException implements Exception {
  final AppErrorCode code;

  const ArticleSummaryGenerationException(this.code);

  @override
  String toString() => 'ArticleSummaryGenerationException: $code';
}
