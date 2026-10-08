import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_pending_inbox_summary.dart';

class MockSummaryRepository extends Mock implements SummaryRepository {}

/// Los resúmenes se guardan con la medianoche local del usuario expresada en
/// UTC (`start.toISOString()` en `generate-daily-summaries`). `DateTime(..)
/// .toUtc()` reproduce exactamente eso para el huso del dispositivo de test:
/// para un usuario al este de UTC (ej. UTC+2) es las 22:00Z del día anterior,
/// y para uno al oeste (ej. UTC-6) las 06:00Z del mismo día.
DailySummary _summary(String id, DateTime localMidnight,
        {DateTime? dismissedAt}) =>
    DailySummary(
      id: id,
      date: localMidnight.toUtc(),
      content: 'contenido',
      articleCount: 3,
      createdAt: localMidnight.toUtc(),
      dismissedAt: dismissedAt,
    );

void main() {
  late MockSummaryRepository repository;
  late GetPendingInboxSummary sut;

  final now = DateTime(2026, 10, 7, 9);
  final today = DateTime(2026, 10, 7);
  final yesterday = DateTime(2026, 10, 6);

  setUp(() {
    repository = MockSummaryRepository();
    sut = GetPendingInboxSummary(repository);
  });

  group('fromSummaries', () {
    test('devuelve el resumen de hoy sin descartar', () {
      final todaySummary = _summary('hoy', today);

      expect(
        sut.fromSummaries([_summary('ayer', yesterday), todaySummary],
            now: now),
        todaySummary,
      );
    });

    test('ignora un resumen de hoy ya descartado', () {
      final dismissed = _summary('hoy', today, dismissedAt: now);

      expect(sut.fromSummaries([dismissed], now: now), isNull);
    });

    test('ignora el resumen de ayer aunque nunca se haya abierto', () {
      expect(sut.fromSummaries([_summary('ayer', yesterday)], now: now),
          isNull);
    });

    test('devuelve null sin resúmenes', () {
      expect(sut.fromSummaries(const [], now: now), isNull);
    });
  });

  test('execute() usa getAll() y no getByDate()', () async {
    when(() => repository.getAll()).thenAnswer((_) async => [
          _summary('hoy', DateTime.now().copyWith(
            hour: 0,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0,
          )),
        ]);

    final result = await sut.execute();

    expect(result?.id, 'hoy');
    verifyNever(() => repository.getByDate(any()));
  });

  test('watch() emite el resumen pendiente ante cada cambio del repositorio',
      () async {
    final todaySummary = _summary(
      'hoy',
      DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      ),
    );
    when(() => repository.watchAll()).thenAnswer(
      (_) => Stream.fromIterable([
        [todaySummary],
        [todaySummary.copyDismissed()],
      ]),
    );

    expect(
      sut.watch(),
      emitsInOrder([todaySummary, null, emitsDone]),
    );
  });
}

extension on DailySummary {
  DailySummary copyDismissed() => DailySummary(
        id: id,
        date: date,
        content: content,
        articleCount: articleCount,
        createdAt: createdAt,
        dismissedAt: DateTime.now(),
      );
}
