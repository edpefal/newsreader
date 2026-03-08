import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';

class GetSourceArticles {
  final ArticleRepository _repository;

  const GetSourceArticles(this._repository);

  Future<List<Article>> execute(String sourceId) =>
      _repository.getArticlesBySource(sourceId);
}
