import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';
import 'package:newsreader/features/reader/domain/usecases/toggle_favorite.dart';

class MockArticleRepository extends Mock implements ArticleRepository {}

class MockCloudSyncClient extends Mock implements CloudSyncClient {}

class MockAuthClient extends Mock implements AuthClient {}

Article _article({required String id, bool isFavorite = false}) => Article(
      id: id,
      sourceId: 's1',
      sourceName: 'Source',
      title: 'Title $id',
      articleUrl: 'https://example.com/$id',
      publishedAt: DateTime(2026),
      isFavorite: isFavorite,
    );

void main() {
  late MockArticleRepository mockRepository;
  late MockCloudSyncClient mockCloudSyncClient;
  late MockAuthClient mockAuthClient;
  late ToggleFavorite sut;

  setUpAll(() {
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(_article(id: 'fallback'));
  });

  setUp(() {
    mockRepository = MockArticleRepository();
    mockCloudSyncClient = MockCloudSyncClient();
    mockAuthClient = MockAuthClient();
    sut = ToggleFavorite(mockRepository, mockCloudSyncClient, mockAuthClient);

    when(() => mockRepository.updateArticle(any())).thenAnswer((_) async {});
    when(() => mockCloudSyncClient.updatePartial(any(), any()))
        .thenAnswer((_) async {});
  });

  test('marca el artículo como favorito localmente', () async {
    when(() => mockRepository.getArticleById('a1'))
        .thenAnswer((_) async => _article(id: 'a1'));
    when(() => mockAuthClient.currentUserId).thenReturn('user-1');

    await sut.execute('a1');

    final updated =
        verify(() => mockRepository.updateArticle(captureAny())).captured.single
            as Article;
    expect(updated.isFavorite, true);
    expect(updated.savedAsFavoriteAt, isNotNull);
  });

  test('desmarca un artículo que ya era favorito', () async {
    when(() => mockRepository.getArticleById('a1'))
        .thenAnswer((_) async => _article(id: 'a1', isFavorite: true));
    when(() => mockAuthClient.currentUserId).thenReturn('user-1');

    await sut.execute('a1');

    final updated =
        verify(() => mockRepository.updateArticle(captureAny())).captured.single
            as Article;
    expect(updated.isFavorite, false);
    expect(updated.savedAsFavoriteAt, isNull);
  });

  test('no hace nada si el artículo no existe', () async {
    when(() => mockRepository.getArticleById('missing'))
        .thenAnswer((_) async => null);

    await sut.execute('missing');

    verifyNever(() => mockRepository.updateArticle(any()));
    verifyNever(() => mockCloudSyncClient.updatePartial(any(), any()));
  });

  group('push inmediato a la nube', () {
    test('con sesión activa, sube el estado del artículo de inmediato', () async {
      when(() => mockRepository.getArticleById('a1'))
          .thenAnswer((_) async => _article(id: 'a1'));
      when(() => mockAuthClient.currentUserId).thenReturn('user-1');

      await sut.execute('a1');
      await Future<void>.delayed(Duration.zero);

      final captured = verify(
        () => mockCloudSyncClient.updatePartial('articles', captureAny()),
      ).captured.single as List<Map<String, dynamic>>;
      expect(captured.single['id'], 'a1');
      expect(captured.single['is_favorite'], true);
    });

    test('sin sesión activa, no intenta ningún push', () async {
      when(() => mockRepository.getArticleById('a1'))
          .thenAnswer((_) async => _article(id: 'a1'));
      when(() => mockAuthClient.currentUserId).thenReturn(null);

      await sut.execute('a1');
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockCloudSyncClient.updatePartial(any(), any()));
    });

    test('si el push falla, no propaga el error ni afecta la actualización local',
        () async {
      when(() => mockRepository.getArticleById('a1'))
          .thenAnswer((_) async => _article(id: 'a1'));
      when(() => mockAuthClient.currentUserId).thenReturn('user-1');
      when(() => mockCloudSyncClient.updatePartial(any(), any())).thenAnswer(
        (_) => Future.error(const CloudSyncException('sin conexión')),
      );

      await expectLater(sut.execute('a1'), completes);
      verify(() => mockRepository.updateArticle(any())).called(1);
    });

    test(
        'no espera la respuesta de red antes de completar execute() (fire-and-forget)',
        () async {
      when(() => mockRepository.getArticleById('a1'))
          .thenAnswer((_) async => _article(id: 'a1'));
      when(() => mockAuthClient.currentUserId).thenReturn('user-1');
      when(() => mockCloudSyncClient.updatePartial(any(), any())).thenAnswer(
        (_) => Future.delayed(const Duration(seconds: 5)),
      );

      await expectLater(
        sut.execute('a1').timeout(const Duration(milliseconds: 200)),
        completes,
      );
    });
  });
}
