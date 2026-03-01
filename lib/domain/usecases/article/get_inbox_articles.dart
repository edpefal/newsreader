import '../../entities/article.dart';
import '../../repositories/article_repository.dart';

class GetInboxArticles {
  final ArticleRepository _repository;

  const GetInboxArticles(this._repository);

  Future<List<Article>> execute() => _repository.getInboxArticles();
}
