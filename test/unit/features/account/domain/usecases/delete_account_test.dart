import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/features/account/domain/usecases/delete_account.dart';
import 'package:newsreader/features/sync/domain/usecases/clear_local_user_data.dart';

class MockHttpClient extends Mock implements HttpClient {}

class MockAuthClient extends Mock implements AuthClient {}

class MockClearLocalUserData extends Mock implements ClearLocalUserData {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockAuthClient mockAuthClient;
  late MockClearLocalUserData mockClearLocalUserData;

  DeleteAccount buildUseCase() =>
      DeleteAccount(mockHttpClient, mockAuthClient, mockClearLocalUserData);

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockAuthClient = MockAuthClient();
    mockClearLocalUserData = MockClearLocalUserData();
    registerFallbackValue(<String, String>{});
  });

  group('DeleteAccount', () {
    test(
        'éxito: borra remoto, limpia datos locales y cierra sesión, en ese orden',
        () async {
      when(() => mockAuthClient.currentAccessToken).thenReturn('token-123');
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => '{"success": true}');
      when(() => mockClearLocalUserData.execute()).thenAnswer((_) async {});
      when(() => mockAuthClient.signOut()).thenAnswer((_) async {});

      await buildUseCase().execute();

      verifyInOrder([
        () => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ),
        () => mockClearLocalUserData.execute(),
        () => mockAuthClient.signOut(),
      ]);
    });

    test('envía el access token en el header Authorization', () async {
      when(() => mockAuthClient.currentAccessToken).thenReturn('mi-token');
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => '{"success": true}');
      when(() => mockClearLocalUserData.execute()).thenAnswer((_) async {});
      when(() => mockAuthClient.signOut()).thenAnswer((_) async {});

      await buildUseCase().execute();

      final captured = verify(() => mockHttpClient.post(
            any(),
            headers: captureAny(named: 'headers'),
            body: any(named: 'body'),
          )).captured;
      expect(captured.single, {'Authorization': 'Bearer mi-token'});
    });

    test(
        'fallo remoto (success=false): no limpia datos locales ni cierra sesión',
        () async {
      when(() => mockAuthClient.currentAccessToken).thenReturn('token-123');
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => '{"error": "Error interno"}');

      await expectLater(
        buildUseCase().execute(),
        throwsA(isA<AccountDeletionException>()),
      );

      verifyNever(() => mockClearLocalUserData.execute());
      verifyNever(() => mockAuthClient.signOut());
    });

    test('fallo de red: propaga la excepción sin limpiar nada', () async {
      when(() => mockAuthClient.currentAccessToken).thenReturn('token-123');
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(const NetworkException());

      await expectLater(
        buildUseCase().execute(),
        throwsA(isA<NetworkException>()),
      );

      verifyNever(() => mockClearLocalUserData.execute());
      verifyNever(() => mockAuthClient.signOut());
    });

    test('sin sesión activa: no invoca la Edge Function', () async {
      when(() => mockAuthClient.currentAccessToken).thenReturn(null);

      await expectLater(
        buildUseCase().execute(),
        throwsA(isA<AccountDeletionException>()),
      );

      verifyNever(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ));
    });
  });
}
