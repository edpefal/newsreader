import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/features/maintenance/domain/usecases/run_maintenance.dart';

class MockArticleRepository extends Mock implements ArticleRepository {}

Article _article({
  required String id,
  bool isRead = false,
  bool isFavorite = false,
  bool isArchived = false,
}) =>
    Article(
      id: id,
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo $id',
      publishedAt: DateTime(2023, 1, 1),
      articleUrl: 'https://example.com/$id',
      isRead: isRead,
      isFavorite: isFavorite,
      isArchived: isArchived,
    );

void main() {
  late MockArticleRepository mockRepository;
  late RunMaintenance sut;

  setUpAll(() {
    registerFallbackValue(_article(id: 'fallback'));
  });

  setUp(() {
    mockRepository = MockArticleRepository();
    sut = RunMaintenance(mockRepository);
  });

  group('RunMaintenance — US-17: limpieza de artículos leídos', () {
    test('elimina artículos leídos y devuelve el conteo correcto', () async {
      final toDelete = [
        _article(id: 'r1', isRead: true),
        _article(id: 'r2', isRead: true),
      ];

      when(() => mockRepository.getReadArticlesOlderThan(any()))
          .thenAnswer((_) async => toDelete);
      when(() => mockRepository.getUnreadNonArchivedArticlesOlderThan(any()))
          .thenAnswer((_) async => []);
      when(() => mockRepository.deleteArticle(any())).thenAnswer((_) async {});

      final result = await sut.execute();

      verify(() => mockRepository.deleteArticle('r1')).called(1);
      verify(() => mockRepository.deleteArticle('r2')).called(1);
      expect(result.deleted, 2);
      expect(result.archived, 0);
    });

    test('no llama deleteArticle cuando no hay artículos leídos viejos',
        () async {
      when(() => mockRepository.getReadArticlesOlderThan(any()))
          .thenAnswer((_) async => []);
      when(() => mockRepository.getUnreadNonArchivedArticlesOlderThan(any()))
          .thenAnswer((_) async => []);

      final result = await sut.execute();

      verifyNever(() => mockRepository.deleteArticle(any()));
      expect(result.deleted, 0);
    });

    test('pasa una fecha de corte de 30 días al repositorio', () async {
      final before = DateTime.now().subtract(const Duration(days: 31));
      final after = DateTime.now().subtract(const Duration(days: 29));

      when(() => mockRepository.getReadArticlesOlderThan(any()))
          .thenAnswer((_) async => []);
      when(() => mockRepository.getUnreadNonArchivedArticlesOlderThan(any()))
          .thenAnswer((_) async => []);

      await sut.execute();

      final captured = verify(
        () => mockRepository.getReadArticlesOlderThan(captureAny()),
      ).captured.first as DateTime;

      expect(captured.isAfter(before), isTrue);
      expect(captured.isBefore(after), isTrue);
    });
  });

  group('RunMaintenance — US-18: archivo automático de no leídos', () {
    test('archiva artículos no leídos y devuelve el conteo correcto', () async {
      final toArchive = [
        _article(id: 'u1'),
        _article(id: 'u2'),
      ];

      when(() => mockRepository.getReadArticlesOlderThan(any()))
          .thenAnswer((_) async => []);
      when(() => mockRepository.getUnreadNonArchivedArticlesOlderThan(any()))
          .thenAnswer((_) async => toArchive);
      when(() => mockRepository.updateArticle(any())).thenAnswer((_) async {});

      final result = await sut.execute();

      final updates = verify(
        () => mockRepository.updateArticle(captureAny()),
      ).captured.cast<Article>();

      expect(updates.length, 2);
      expect(updates.every((a) => a.isArchived), isTrue);
      expect(result.archived, 2);
      expect(result.deleted, 0);
    });

    test('no llama updateArticle cuando no hay artículos no leídos viejos',
        () async {
      when(() => mockRepository.getReadArticlesOlderThan(any()))
          .thenAnswer((_) async => []);
      when(() => mockRepository.getUnreadNonArchivedArticlesOlderThan(any()))
          .thenAnswer((_) async => []);

      final result = await sut.execute();

      verifyNever(() => mockRepository.updateArticle(any()));
      expect(result.archived, 0);
    });

    test('usa la misma fecha de corte para ambas consultas', () async {
      when(() => mockRepository.getReadArticlesOlderThan(any()))
          .thenAnswer((_) async => []);
      when(() => mockRepository.getUnreadNonArchivedArticlesOlderThan(any()))
          .thenAnswer((_) async => []);

      await sut.execute();

      final deleteCutoff = verify(
        () => mockRepository.getReadArticlesOlderThan(captureAny()),
      ).captured.first as DateTime;

      final archiveCutoff = verify(
        () => mockRepository.getUnreadNonArchivedArticlesOlderThan(captureAny()),
      ).captured.first as DateTime;

      expect(
        deleteCutoff.difference(archiveCutoff).inSeconds.abs(),
        lessThan(2),
      );
    });
  });

  group('RunMaintenance — combinado', () {
    test('ejecuta delete y archive en la misma llamada', () async {
      final toDelete = [_article(id: 'r1', isRead: true)];
      final toArchive = [_article(id: 'u1')];

      when(() => mockRepository.getReadArticlesOlderThan(any()))
          .thenAnswer((_) async => toDelete);
      when(() => mockRepository.getUnreadNonArchivedArticlesOlderThan(any()))
          .thenAnswer((_) async => toArchive);
      when(() => mockRepository.deleteArticle(any())).thenAnswer((_) async {});
      when(() => mockRepository.updateArticle(any())).thenAnswer((_) async {});

      final result = await sut.execute();

      verify(() => mockRepository.deleteArticle('r1')).called(1);
      verify(() => mockRepository.updateArticle(any())).called(1);
      expect(result.deleted, 1);
      expect(result.archived, 1);
    });
  });
}
