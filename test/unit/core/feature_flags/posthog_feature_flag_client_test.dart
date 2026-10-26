import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/feature_flags/posthog_feature_flag_client.dart';

void main() {
  PostHogFeatureFlagClient clientReturning(Object? value) =>
      PostHogFeatureFlagClient(readFlag: (_) async => value);

  group('PostHogFeatureFlagClient.isEnabled', () {
    test('devuelve true solo cuando el flag vale true', () async {
      expect(await clientReturning(true).isEnabled('email-login'), isTrue);
    });

    test('devuelve false cuando el flag vale false', () async {
      expect(await clientReturning(false).isEnabled('email-login'), isFalse);
    });

    test('devuelve false para un flag inexistente (null)', () async {
      expect(await clientReturning(null).isEnabled('email-login'), isFalse);
    });

    test('devuelve false para un valor que no es booleano', () async {
      expect(await clientReturning('test').isEnabled('email-login'), isFalse);
    });

    test('devuelve false si el SDK lanza una excepción', () async {
      final sut = PostHogFeatureFlagClient(
        readFlag: (_) async => throw Exception('sdk no listo'),
      );

      expect(await sut.isEnabled('email-login'), isFalse);
    });

    test('consulta la clave pedida', () async {
      String? asked;
      final sut = PostHogFeatureFlagClient(
        readFlag: (key) async {
          asked = key;
          return true;
        },
      );

      await sut.isEnabled('email-login');

      expect(asked, 'email-login');
    });
  });

  group('PostHogFeatureFlagClient.changes', () {
    test('notifyChanged emite a los suscriptores', () async {
      final sut = clientReturning(true);
      final emissions = <void>[];
      final sub = sut.changes.listen(emissions.add);

      sut.notifyChanged();
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
      await sub.cancel();
    });

    test('permite varios suscriptores a la vez', () async {
      final sut = clientReturning(true);
      var a = 0;
      var b = 0;
      final subA = sut.changes.listen((_) => a++);
      final subB = sut.changes.listen((_) => b++);

      sut.notifyChanged();
      await Future<void>.delayed(Duration.zero);

      expect([a, b], [1, 1]);
      await subA.cancel();
      await subB.cancel();
    });
  });
}
