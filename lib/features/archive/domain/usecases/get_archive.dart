import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';

class GetArchive {
  final ArticleRepository _repository;

  const GetArchive(this._repository);

  Future<List<Article>> execute() => _repository.getArchive();
}
