import '../../entities/article.dart';
import '../../repositories/article_repository.dart';

class GetFavorites {
  final ArticleRepository _repository;

  const GetFavorites(this._repository);

  Future<List<Article>> execute() => _repository.getFavorites();
}
