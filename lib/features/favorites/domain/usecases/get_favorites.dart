import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';

class GetFavorites {
  final ArticleRepository _repository;

  const GetFavorites(this._repository);

  Future<List<Article>> execute() => _repository.getFavorites();
}
