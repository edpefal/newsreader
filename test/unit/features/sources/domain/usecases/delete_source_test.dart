import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';
import 'package:newsreader/features/sources/domain/usecases/delete_source.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

import '../../../../../support/fake_telemetry_client.dart';

class MockSourceRepository extends Mock implements SourceRepository {}

class MockArticleRepository extends Mock implements ArticleRepository {}

class MockSyncUserData extends Mock implements SyncUserData {}

class MockAuthClient extends Mock implements AuthClient {}

void main() {
  late MockSourceRepository mockSourceRepository;
  late MockArticleRepository mockArticleRepository;
  late MockSyncUserData mockSyncUserData;
  late MockAuthClient mockAuthClient;
  late MockTelemetryClient mockTelemetryClient;
  late DeleteSource sut;

  setUp(() {
    mockSourceRepository = MockSourceRepository();
    mockArticleRepository = MockArticleRepository();
    mockSyncUserData = MockSyncUserData();
    mockAuthClient = MockAuthClient();
    mockTelemetryClient = MockTelemetryClient();
    sut = DeleteSource(
      mockSourceRepository,
      mockArticleRepository,
      mockSyncUserData,
      mockAuthClient,
      mockTelemetryClient,
    );

    when(() => mockArticleRepository.deleteArticlesBySource(
          any(),
          keepFavorites: any(named: 'keepFavorites'),
        )).thenAnswer((_) async {});
    when(() => mockSourceRepository.deleteSource(any()))
        .thenAnswer((_) async {});
    when(() => mockSyncUserData.execute()).thenAnswer((_) async {});
  });

  test('borra los artículos de la fuente (conservando favoritos) y la fuente misma',
      () async {
    when(() => mockAuthClient.currentUserId).thenReturn(null);

    await sut.execute('s1');

    verify(() => mockArticleRepository.deleteArticlesBySource(
          's1',
          keepFavorites: true,
        )).called(1);
    verify(() => mockSourceRepository.deleteSource('s1')).called(1);
  });

  group('push inmediato a la nube', () {
    test('con sesión activa, sube el borrado de inmediato', () async {
      when(() => mockAuthClient.currentUserId).thenReturn('user-1');

      await sut.execute('s1');
      await Future<void>.delayed(Duration.zero);

      verify(() => mockSyncUserData.execute()).called(1);
    });

    test('sin sesión activa, no intenta ningún push', () async {
      when(() => mockAuthClient.currentUserId).thenReturn(null);

      await sut.execute('s1');
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockSyncUserData.execute());
    });

    test('si el push falla, no propaga el error ni afecta el borrado local',
        () async {
      when(() => mockAuthClient.currentUserId).thenReturn('user-1');
      when(() => mockSyncUserData.execute())
          .thenThrow(const CloudSyncException('sin conexión'));

      await expectLater(sut.execute('s1'), completes);
      verify(() => mockSourceRepository.deleteSource('s1')).called(1);
    });

    test(
        'no espera la respuesta de red antes de completar execute() (fire-and-forget)',
        () async {
      when(() => mockAuthClient.currentUserId).thenReturn('user-1');
      when(() => mockSyncUserData.execute()).thenAnswer(
        (_) => Future.delayed(const Duration(seconds: 5)),
      );

      await expectLater(
        sut.execute('s1').timeout(const Duration(milliseconds: 200)),
        completes,
      );
    });
  });
}
