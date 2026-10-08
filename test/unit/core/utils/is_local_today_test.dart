import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/utils/is_local_today.dart';

void main() {
  final now = DateTime(2026, 10, 7, 15, 30);

  test(
      'la medianoche local de hoy expresada en UTC (como la guarda el servidor) es hoy, sea cual sea el huso del dispositivo',
      () {
    final storedByServer = DateTime(2026, 10, 7).toUtc();

    expect(isLocalToday(storedByServer, now: now), isTrue);
  });

  test('la medianoche local de ayer expresada en UTC no es hoy', () {
    final yesterday = DateTime(2026, 10, 6).toUtc();

    expect(isLocalToday(yesterday, now: now), isFalse);
  });

  test('un instante de la tarde de hoy sigue siendo hoy', () {
    expect(isLocalToday(DateTime(2026, 10, 7, 23, 59), now: now), isTrue);
  });

  test('mañana a medianoche local no es hoy', () {
    expect(isLocalToday(DateTime(2026, 10, 8), now: now), isFalse);
  });
}
