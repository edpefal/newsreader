import 'package:newsreader/core/domain/repositories/article_repository.dart';

class MarkArticleAsRead {
  final ArticleRepository _repository;

  const MarkArticleAsRead(this._repository);

  Future<void> execute(String articleId) async {
    final article = await _repository.getArticleById(articleId);
    if (article == null || article.isRead) return;
    await _repository.updateArticle(
      article.copyWith(isRead: true, readAt: DateTime.now()),
    );
  }
}
