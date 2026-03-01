import '../../entities/article.dart';
import '../../repositories/article_repository.dart';

class GetArchive {
  final ArticleRepository _repository;

  const GetArchive(this._repository);

  Future<List<Article>> execute() => _repository.getArchive();
}
