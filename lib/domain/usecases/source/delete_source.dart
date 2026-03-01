import '../../repositories/article_repository.dart';
import '../../repositories/source_repository.dart';

class DeleteSource {
  final SourceRepository _sourceRepository;
  final ArticleRepository _articleRepository;

  const DeleteSource(this._sourceRepository, this._articleRepository);

  Future<void> execute(String sourceId) async {
    await _articleRepository.deleteArticlesBySource(
      sourceId,
      keepFavorites: true,
    );
    await _sourceRepository.deleteSource(sourceId);
  }
}
