import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';
import 'package:newsreader/features/inbox/domain/usecases/dismiss_daily_summary.dart';

import '../../../../../support/fake_telemetry_client.dart';

class MockSummaryRepository extends Mock implements SummaryRepository {}

class MockCloudSyncClient extends Mock implements CloudSyncClient {}

class MockAuthClient extends Mock implements AuthClient {}

DailySummary _summary(DateTime localMidnight, {DateTime? dismissedAt}) =>
    DailySummary(
      id: 'summary-1',
      date: localMidnight.toUtc(),
      content: 'contenido',
      articleCount: 3,
      createdAt: localMidnight.toUtc(),
      updatedAt: dismissedAt,
      dismissedAt: dismissedAt,
    );

DateTime _todayMidnight() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  late MockSummaryRepository repository;
  late MockCloudSyncClient cloudSyncClient;
  late MockAuthClient authClient;
  late MockTelemetryClient telemetry;
  late DismissDailySummary sut;

  setUpAll(() {
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    repository = MockSummaryRepository();
    cloudSyncClient = MockCloudSyncClient();
    authClient = MockAuthClient();
    telemetry = MockTelemetryClient();
    sut = DismissDailySummary(repository, cloudSyncClient, authClient, telemetry);

    when(() => cloudSyncClient.updatePartial(any(), any()))
        .thenAnswer((_) async {});
    when(() => authClient.currentUserId).thenReturn('user-1');
  });

  void stubTodayDismiss() {
    final dismissedAt = DateTime.now();
    when(() => repository.getById('summary-1'))
        .thenAnswer((_) async => _summary(_todayMidnight()));
    when(() => repository.dismiss('summary-1')).thenAnswer(
      (_) async => _summary(_todayMidnight(), dismissedAt: dismissedAt),
    );
  }

  test('descarta el resumen de hoy y sube solo dismissed_at y updated_at',
      () async {
    stubTodayDismiss();

    await sut.execute('summary-1');
    await Future<void>.delayed(Duration.zero);

    verify(() => repository.dismiss('summary-1')).called(1);
    final rows = verify(
      () => cloudSyncClient.updatePartial('daily_summaries', captureAny()),
    ).captured.single as List<Map<String, dynamic>>;
    expect(rows.single.keys, {'id', 'dismissed_at', 'updated_at'});
    expect(rows.single['id'], 'summary-1');
  });

  test('un resumen de un día anterior no se descarta ni se sube', () async {
    when(() => repository.getById('summary-1')).thenAnswer((_) async =>
        _summary(_todayMidnight().subtract(const Duration(days: 1))));

    await sut.execute('summary-1');

    verifyNever(() => repository.dismiss(any()));
    verifyNever(() => cloudSyncClient.updatePartial(any(), any()));
  });

  test('un resumen inexistente no hace nada', () async {
    when(() => repository.getById('summary-1')).thenAnswer((_) async => null);

    await sut.execute('summary-1');

    verifyNever(() => repository.dismiss(any()));
  });

  test('es idempotente: si ya estaba descartado no vuelve a subir', () async {
    when(() => repository.getById('summary-1'))
        .thenAnswer((_) async => _summary(_todayMidnight()));
    when(() => repository.dismiss('summary-1')).thenAnswer((_) async => null);

    await sut.execute('summary-1');

    verifyNever(() => cloudSyncClient.updatePartial(any(), any()));
  });

  test('sin sesión activa descarta localmente y no intenta el push', () async {
    stubTodayDismiss();
    when(() => authClient.currentUserId).thenReturn(null);

    await sut.execute('summary-1');

    verify(() => repository.dismiss('summary-1')).called(1);
    verifyNever(() => cloudSyncClient.updatePartial(any(), any()));
  });

  test('si el push falla (sin red) no propaga el error y lo reporta',
      () async {
    stubTodayDismiss();
    when(() => cloudSyncClient.updatePartial(any(), any()))
        .thenThrow(Exception('sin red'));

    await expectLater(sut.execute('summary-1'), completes);
    await Future<void>.delayed(Duration.zero);

    verify(() => repository.dismiss('summary-1')).called(1);
    verify(
      () => telemetry.captureException(
        any(),
        any(),
        context: const {'operation': 'dismiss_push'},
      ),
    ).called(1);
  });

  test('si falla la persistencia local no propaga el error y lo reporta',
      () async {
    when(() => repository.getById('summary-1'))
        .thenAnswer((_) async => _summary(_todayMidnight()));
    when(() => repository.dismiss('summary-1')).thenThrow(Exception('hive'));

    await expectLater(sut.execute('summary-1'), completes);

    verify(
      () => telemetry.captureException(
        any(),
        any(),
        context: const {'operation': 'dismiss'},
      ),
    ).called(1);
    verifyNever(() => cloudSyncClient.updatePartial(any(), any()));
  });
}
