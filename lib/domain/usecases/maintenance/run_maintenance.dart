import '../../../core/constants/app_constants.dart';
import '../../repositories/article_repository.dart';

class MaintenanceResult {
  final int deleted;
  final int archived;

  const MaintenanceResult({required this.deleted, required this.archived});
}

class RunMaintenance {
  final ArticleRepository _repository;

  const RunMaintenance(this._repository);

  Future<MaintenanceResult> execute() async {
    final cutoff = DateTime.now().subtract(
      const Duration(days: AppConstants.cleanupDays),
    );

    final toDelete = await _repository.getReadArticlesOlderThan(cutoff);
    for (final article in toDelete) {
      await _repository.deleteArticle(article.id);
    }

    final toArchive =
        await _repository.getUnreadNonArchivedArticlesOlderThan(cutoff);
    for (final article in toArchive) {
      await _repository.updateArticle(article.copyWith(isArchived: true));
    }

    return MaintenanceResult(
      deleted: toDelete.length,
      archived: toArchive.length,
    );
  }
}
