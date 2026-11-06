import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/settings/domain/usecases/restore_purchases.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_entitlement.dart';

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

class MockSyncEntitlement extends Mock implements SyncEntitlement {}

class MockTelemetryClient extends Mock implements TelemetryClient {}

void main() {
  late MockSubscriptionStatusProvider provider;
  late MockSyncEntitlement syncEntitlement;
  late MockTelemetryClient telemetry;
  late RestorePurchases restorePurchases;

  setUp(() {
    provider = MockSubscriptionStatusProvider();
    syncEntitlement = MockSyncEntitlement();
    telemetry = MockTelemetryClient();
    restorePurchases = RestorePurchases(provider, syncEntitlement, telemetry);
    when(() => syncEntitlement.execute()).thenAnswer((_) async => true);
  });

  test(
    'con una suscripción vigente sincroniza el entitlement y lo registra',
    () async {
      when(() => provider.restore()).thenAnswer((_) async => true);

      expect(await restorePurchases.execute(), isTrue);

      verify(() => syncEntitlement.execute()).called(1);
      verify(
        () => telemetry.trackEvent(
          'restore_completed',
          properties: {'found': true},
        ),
      ).called(1);
    },
  );

  test(
    'sin compras que restaurar no sincroniza y registra found = false',
    () async {
      when(() => provider.restore()).thenAnswer((_) async => false);

      expect(await restorePurchases.execute(), isFalse);

      verifyNever(() => syncEntitlement.execute());
      verify(
        () => telemetry.trackEvent(
          'restore_completed',
          properties: {'found': false},
        ),
      ).called(1);
    },
  );

  test(
    'si la restauración falla, propaga la excepción sin registrar evento',
    () async {
      when(() => provider.restore()).thenThrow(
        const SubscriptionException(AppErrorCode.restoreFailed, 'storeProblem'),
      );

      await expectLater(
        restorePurchases.execute(),
        throwsA(isA<SubscriptionException>()),
      );
      verifyNever(() => syncEntitlement.execute());
      verifyNever(
        () => telemetry.trackEvent(
          'restore_completed',
          properties: any(named: 'properties'),
        ),
      );
    },
  );
}
