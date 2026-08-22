import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/email_feed/email_feed_generator.dart';
import 'package:newsreader/core/email_feed/supabase_email_feed_generator.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/network/http_client.dart';

import '../../../support/fake_observability_client.dart';

class MockHttpClient extends Mock implements HttpClient {}

class MockAuthClient extends Mock implements AuthClient {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockAuthClient mockAuthClient;
  late MockObservabilityClient mockObservabilityClient;
  late SupabaseEmailFeedGenerator sut;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockAuthClient = MockAuthClient();
    mockObservabilityClient = MockObservabilityClient();
    when(() => mockAuthClient.currentAccessToken).thenReturn('token-de-sesion');
    sut = SupabaseEmailFeedGenerator(
      mockHttpClient,
      mockAuthClient,
      mockObservabilityClient,
    );
  });

  test('devuelve email y feedUrl del backend en caso exitoso', () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (_) async =>
          '{"id": "abc", "email": "abc@dominio.com", "feedUrl": "https://x/feed/abc"}',
    );

    final result = await sut.generate(label: 'Mi Newsletter');

    expect(result.email, 'abc@dominio.com');
    expect(result.feedUrl, 'https://x/feed/abc');
  });

  test('envía el label en el body cuando se provee', () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (_) async => '{"email": "a@b.com", "feedUrl": "https://x/feed/a"}',
    );

    await sut.generate(label: 'Mi Newsletter');

    final captured = verify(
      () => mockHttpClient.post(
        any(),
        body: captureAny(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).captured;
    expect(captured.single, contains('Mi Newsletter'));
  });

  test('lanza EmailFeedGenerationException si el backend responde con error',
      () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((_) async => '{"error": "Límite alcanzado"}');

    expect(
      sut.generate(),
      throwsA(isA<EmailFeedGenerationException>()),
    );
  });

  test('lanza EmailFeedGenerationException si falla la request HTTP', () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenThrow(const NetworkException());

    expect(
      sut.generate(),
      throwsA(isA<EmailFeedGenerationException>()),
    );
  });

  test(
      'lanza EmailFeedGenerationException sin accessToken y no llama al HttpClient',
      () async {
    when(() => mockAuthClient.currentAccessToken).thenReturn(null);

    expect(sut.generate(), throwsA(isA<EmailFeedGenerationException>()));
    verifyNever(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    );
  });

  test('usa el accessToken de la sesión como Authorization, no la anon key',
      () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (_) async => '{"email": "a@b.com", "feedUrl": "https://x/feed/a"}',
    );

    await sut.generate();

    final headers = verify(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: captureAny(named: 'headers'),
      ),
    ).captured.single as Map<String, String>;

    expect(headers['Authorization'], 'Bearer token-de-sesion');
  });
}
