import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';

class GetInboxArticles {
  final ArticleRepository _repository;

  const GetInboxArticles(this._repository);

  Future<List<Article>> execute() => _repository.getInboxArticles();
}
