import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';
import 'package:newsreader/features/sources/domain/usecases/update_source_name.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

import '../../../../../support/fake_telemetry_client.dart';

class MockSourceRepository extends Mock implements SourceRepository {}

class MockSyncUserData extends Mock implements SyncUserData {}

class MockAuthClient extends Mock implements AuthClient {}

NewsSource _source({required String id, String name = 'Fuente'}) => NewsSource(
      id: id,
      name: name,
      feedUrl: 'https://example.com/$id/feed',
      addedAt: DateTime(2026),
    );

void main() {
  late MockSourceRepository mockSourceRepository;
  late MockSyncUserData mockSyncUserData;
  late MockAuthClient mockAuthClient;
  late MockTelemetryClient mockTelemetryClient;
  late UpdateSourceName sut;

  setUpAll(() {
    registerFallbackValue(_source(id: 'fallback'));
  });

  setUp(() {
    mockSourceRepository = MockSourceRepository();
    mockSyncUserData = MockSyncUserData();
    mockAuthClient = MockAuthClient();
    mockTelemetryClient = MockTelemetryClient();
    sut = UpdateSourceName(
      mockSourceRepository,
      mockSyncUserData,
      mockAuthClient,
      mockTelemetryClient,
    );

    when(() => mockSourceRepository.getSources())
        .thenAnswer((_) async => [_source(id: 's1')]);
    when(() => mockSourceRepository.updateSource(any()))
        .thenAnswer((_) async {});
    when(() => mockSyncUserData.execute()).thenAnswer((_) async {});
  });

  test('actualiza el nombre de la fuente localmente', () async {
    when(() => mockAuthClient.currentUserId).thenReturn(null);

    await sut.execute('s1', 'Nuevo Nombre');

    final updated = verify(
      () => mockSourceRepository.updateSource(captureAny()),
    ).captured.single as NewsSource;
    expect(updated.name, 'Nuevo Nombre');
  });

  group('push inmediato a la nube', () {
    test('con sesión activa, sube el nuevo nombre de inmediato', () async {
      when(() => mockAuthClient.currentUserId).thenReturn('user-1');

      await sut.execute('s1', 'Nuevo Nombre');
      await Future<void>.delayed(Duration.zero);

      verify(() => mockSyncUserData.execute()).called(1);
    });

    test('sin sesión activa, no intenta ningún push', () async {
      when(() => mockAuthClient.currentUserId).thenReturn(null);

      await sut.execute('s1', 'Nuevo Nombre');
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockSyncUserData.execute());
    });

    test('si el push falla, no propaga el error ni afecta la actualización local',
        () async {
      when(() => mockAuthClient.currentUserId).thenReturn('user-1');
      when(() => mockSyncUserData.execute())
          .thenThrow(const CloudSyncException('sin conexión'));

      await expectLater(sut.execute('s1', 'Nuevo Nombre'), completes);
      verify(() => mockSourceRepository.updateSource(any())).called(1);
    });

    test(
        'no espera la respuesta de red antes de completar execute() (fire-and-forget)',
        () async {
      when(() => mockAuthClient.currentUserId).thenReturn('user-1');
      when(() => mockSyncUserData.execute()).thenAnswer(
        (_) => Future.delayed(const Duration(seconds: 5)),
      );

      await expectLater(
        sut.execute('s1', 'Nuevo Nombre').timeout(const Duration(milliseconds: 200)),
        completes,
      );
    });
  });
}
