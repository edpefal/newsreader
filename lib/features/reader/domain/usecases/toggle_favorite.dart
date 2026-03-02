import 'package:newsreader/core/domain/repositories/article_repository.dart';

class ToggleFavorite {
  final ArticleRepository _repository;

  const ToggleFavorite(this._repository);

  Future<void> execute(String articleId) async {
    final article = await _repository.getArticleById(articleId);
    if (article == null) return;

    final nowFavorite = !article.isFavorite;
    await _repository.updateArticle(
      article.copyWith(
        isFavorite: nowFavorite,
        savedAsFavoriteAt: nowFavorite ? DateTime.now() : null,
      ),
    );
  }
}
