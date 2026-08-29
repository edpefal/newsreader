import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/main.dart';

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

class MockTelemetryClient extends Mock implements TelemetryClient {}

void main() {
  late MockSubscriptionStatusProvider mockSubscriptionStatusProvider;
  late MockTelemetryClient mockTelemetryClient;

  setUp(() {
    mockSubscriptionStatusProvider = MockSubscriptionStatusProvider();
    mockTelemetryClient = MockTelemetryClient();

    when(() => mockSubscriptionStatusProvider.identify(any()))
        .thenAnswer((_) async {});
    when(() => mockSubscriptionStatusProvider.reset()).thenAnswer((_) async {});
  });

  test('al iniciar sesión, asocia el userId a observabilidad', () {
    handleAuthStateChange(
      true,
      'user-1',
      mockSubscriptionStatusProvider,
      mockTelemetryClient,
    );

    verify(() => mockTelemetryClient.setUserId('user-1')).called(1);
    verifyNever(() => mockTelemetryClient.setUserId(null));
  });

  test('al cerrar sesión, desasocia al usuario de observabilidad', () {
    handleAuthStateChange(
      false,
      null,
      mockSubscriptionStatusProvider,
      mockTelemetryClient,
    );

    verify(() => mockTelemetryClient.setUserId(null)).called(1);
  });
}
