import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/features/maintenance/domain/usecases/migrate_archived_articles.dart';

class MockArticleRepository extends Mock implements ArticleRepository {}

Article _article({
  required String id,
  bool isArchived = false,
  bool isRead = false,
}) =>
    Article(
      id: id,
      sourceId: 's1',
      sourceName: 'Source',
      title: 'Title',
      publishedAt: DateTime(2024),
      articleUrl: 'https://example.com/$id',
      isArchived: isArchived,
      isRead: isRead,
    );

void main() {
  late MockArticleRepository mockRepo;
  late MigrateArchivedArticles sut;

  setUp(() {
    mockRepo = MockArticleRepository();
    sut = MigrateArchivedArticles(mockRepo);
    when(() => mockRepo.deleteArticle(any())).thenAnswer((_) async {});
  });

  test('elimina todos los artículos con isArchived=true', () async {
    when(() => mockRepo.getArchivedArticles()).thenAnswer(
      (_) async => [
        _article(id: 'a1', isArchived: true),
        _article(id: 'a2', isArchived: true),
      ],
    );

    await sut.execute();

    verify(() => mockRepo.deleteArticle('a1')).called(1);
    verify(() => mockRepo.deleteArticle('a2')).called(1);
  });

  test('no elimina nada si no hay artículos archivados', () async {
    when(() => mockRepo.getArchivedArticles()).thenAnswer((_) async => []);

    await sut.execute();

    verifyNever(() => mockRepo.deleteArticle(any()));
  });
}
