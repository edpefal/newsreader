import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';

/// Resuelve los artículos referenciados por un [DailySummary.sourceBlocks],
/// descartando en silencio los ids que ya no correspondan a ningún artículo
/// local (ej. su fuente fue eliminada después de generar el resumen).
class ResolveSummaryArticles {
  final ArticleRepository _articleRepository;

  const ResolveSummaryArticles(this._articleRepository);

  Future<Map<String, Article>> execute(List<String> articleIds) async {
    final result = <String, Article>{};
    for (final id in articleIds) {
      final article = await _articleRepository.getArticleById(id);
      if (article != null) result[id] = article;
    }
    return result;
  }
}
