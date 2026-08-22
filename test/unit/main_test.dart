import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/observability/observability_client.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/main.dart';

class MockSubscriptionStatusProvider extends Mock
    implements SubscriptionStatusProvider {}

class MockObservabilityClient extends Mock implements ObservabilityClient {}

void main() {
  late MockSubscriptionStatusProvider mockSubscriptionStatusProvider;
  late MockObservabilityClient mockObservabilityClient;

  setUp(() {
    mockSubscriptionStatusProvider = MockSubscriptionStatusProvider();
    mockObservabilityClient = MockObservabilityClient();

    when(() => mockSubscriptionStatusProvider.identify(any()))
        .thenAnswer((_) async {});
    when(() => mockSubscriptionStatusProvider.reset()).thenAnswer((_) async {});
  });

  test('al iniciar sesión, asocia el userId a observabilidad', () {
    handleAuthStateChange(
      true,
      'user-1',
      mockSubscriptionStatusProvider,
      mockObservabilityClient,
    );

    verify(() => mockObservabilityClient.setUserId('user-1')).called(1);
    verifyNever(() => mockObservabilityClient.setUserId(null));
  });

  test('al cerrar sesión, desasocia al usuario de observabilidad', () {
    handleAuthStateChange(
      false,
      null,
      mockSubscriptionStatusProvider,
      mockObservabilityClient,
    );

    verify(() => mockObservabilityClient.setUserId(null)).called(1);
  });
}
