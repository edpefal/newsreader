import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai/gemini_summary_generator.dart';
import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';

import '../../../support/fake_telemetry_client.dart';

class MockHttpClient extends Mock implements HttpClient {}

class MockAuthClient extends Mock implements AuthClient {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockAuthClient mockAuthClient;
  late MockTelemetryClient mockTelemetryClient;
  late GeminiSummaryGenerator sut;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(TelemetryLevel.info);
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockAuthClient = MockAuthClient();
    mockTelemetryClient = MockTelemetryClient();
    when(() => mockAuthClient.currentAccessToken).thenReturn('token-de-sesion');
    sut = GeminiSummaryGenerator(
      mockHttpClient,
      mockAuthClient,
      mockTelemetryClient,
    );
  });

  final tArticles = [
    (title: 'Título 1', excerpt: 'Extracto 1', sourceName: 'Fuente A'),
    (title: 'Título 2', excerpt: 'Extracto 2', sourceName: 'Fuente B'),
  ];

  test('lanza SummaryGenerationException si la lista está vacía', () {
    expect(
      sut.summarize([], language: 'es'),
      throwsA(isA<SummaryGenerationException>()),
    );
    verifyNever(
      () => mockHttpClient.post(any(), body: any(named: 'body')),
    );
  });

  test('devuelve el summary del backend en caso exitoso', () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => '{"summary": "Resumen generado"}');

    final result = await sut.summarize(tArticles, language: 'es');

    expect(result, 'Resumen generado');
  });

  test('incluye el language en el body del POST', () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => '{"summary": "Resumen generado"}');

    await sut.summarize(tArticles, language: 'fr');

    final body = verify(
      () => mockHttpClient.post(
        any(),
        body: captureAny(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).captured.single as String;

    expect(jsonDecode(body) as Map, containsPair('language', 'fr'));
  });

  test('lanza SummaryGenerationException si el backend responde con error', () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => '{"error": "Backend mal configurado"}');

    await expectLater(
      sut.summarize(tArticles, language: 'es'),
      throwsA(
        isA<SummaryGenerationException>()
            .having((e) => e.code, 'code', AppErrorCode.generationFailed),
      ),
    );
    verify(
      () => mockTelemetryClient.captureMessage(
        any(that: contains('Backend mal configurado')),
        level: TelemetryLevel.warning,
      ),
    ).called(1);
  });

  test(
      'no llama captureMessage cuando el backend responde ai_usage_limit_reached',
      () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => '{"error": "ai_usage_limit_reached"}');

    await expectLater(
      sut.summarize(tArticles, language: 'es'),
      throwsA(
        isA<SummaryGenerationException>()
            .having((e) => e.code, 'code', AppErrorCode.aiUsageLimitReached),
      ),
    );
    verifyNever(
      () => mockTelemetryClient.captureMessage(any(), level: any(named: 'level')),
    );
  });

  test(
      'lanza AppErrorCode.subscriptionRequired sin llamar captureMessage cuando el backend responde subscription_required',
      () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => '{"error": "subscription_required"}');

    await expectLater(
      sut.summarize(tArticles, language: 'es'),
      throwsA(
        isA<SummaryGenerationException>()
            .having((e) => e.code, 'code', AppErrorCode.subscriptionRequired),
      ),
    );
    verifyNever(
      () => mockTelemetryClient.captureMessage(any(), level: any(named: 'level')),
    );
  });

  test('usa un timeout más largo que el default de fetch de feeds', () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => '{"summary": "Resumen generado"}');

    await sut.summarize(tArticles, language: 'es');

    final captured = verify(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: captureAny(named: 'timeout'),
      ),
    ).captured.single as Duration;

    expect(captured, AppConstants.summaryGenerationTimeout);
    expect(captured, greaterThan(AppConstants.feedFetchTimeout));
  });

  test('lanza SummaryGenerationException si falla la request HTTP', () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).thenThrow(const NetworkException());

    expect(sut.summarize(tArticles, language: 'es'), throwsA(isA<SummaryGenerationException>()));
  });

  test(
      'relanza SummaryGenerationException con AppErrorCode.timeout si el HttpClient da timeout',
      () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).thenThrow(const TimeoutException());

    await expectLater(
      sut.summarize(tArticles, language: 'es'),
      throwsA(
        isA<SummaryGenerationException>()
            .having((e) => e.code, 'code', AppErrorCode.timeout),
      ),
    );
  });

  test(
      'relanza SummaryGenerationException con AppErrorCode.network si el HttpClient falla por red',
      () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).thenThrow(const NetworkException());

    await expectLater(
      sut.summarize(tArticles, language: 'es'),
      throwsA(
        isA<SummaryGenerationException>()
            .having((e) => e.code, 'code', AppErrorCode.network),
      ),
    );
  });

  test(
      'lanza SummaryGenerationException sin accessToken y no llama al HttpClient',
      () async {
    when(() => mockAuthClient.currentAccessToken).thenReturn(null);

    expect(sut.summarize(tArticles, language: 'es'), throwsA(isA<SummaryGenerationException>()));
    verifyNever(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
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
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => '{"summary": "Resumen generado"}');

    await sut.summarize(tArticles, language: 'es');

    final headers = verify(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: captureAny(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).captured.single as Map<String, String>;

    expect(headers['Authorization'], 'Bearer token-de-sesion');
  });
}
