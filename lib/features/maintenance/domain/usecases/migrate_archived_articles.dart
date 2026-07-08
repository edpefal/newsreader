import 'package:newsreader/core/domain/repositories/article_repository.dart';

class MigrateArchivedArticles {
  final ArticleRepository _repository;

  const MigrateArchivedArticles(this._repository);

  Future<void> execute() async {
    final archived = await _repository.getArchivedArticles();
    for (final article in archived) {
      await _repository.deleteArticle(article.id);
    }
  }
}
