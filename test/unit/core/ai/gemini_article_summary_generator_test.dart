import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai/article_summary_generator.dart';
import 'package:newsreader/core/ai/gemini_article_summary_generator.dart';
import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/network/http_client.dart';

import '../../../support/fake_observability_client.dart';

class MockHttpClient extends Mock implements HttpClient {}

class MockAuthClient extends Mock implements AuthClient {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockAuthClient mockAuthClient;
  late MockObservabilityClient mockObservabilityClient;
  late GeminiArticleSummaryGenerator sut;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockAuthClient = MockAuthClient();
    mockObservabilityClient = MockObservabilityClient();
    when(() => mockAuthClient.currentAccessToken).thenReturn('token-de-sesion');
    sut = GeminiArticleSummaryGenerator(
      mockHttpClient,
      mockAuthClient,
      mockObservabilityClient,
    );
  });

  void mockPost(String responseBody) {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => responseBody);
  }

  test('devuelve el summary y las mentions del backend en caso exitoso', () async {
    mockPost(
      jsonEncode({
        'summary': 'Resumen del artículo',
        'mentions': [
          {'type': 'book', 'name': 'Un libro'},
        ],
      }),
    );

    final result = await sut.summarizeArticle(
      'Título',
      'Contenido',
      language: 'es',
    );

    expect(result.summary, 'Resumen del artículo');
    expect(result.mentions, hasLength(1));
    expect(result.mentions.first.name, 'Un libro');
  });

  test(
      'lanza ArticleSummaryGenerationException sin accessToken y no llama al HttpClient',
      () async {
    when(() => mockAuthClient.currentAccessToken).thenReturn(null);

    expect(
      sut.summarizeArticle('Título', 'Contenido', language: 'es'),
      throwsA(isA<ArticleSummaryGenerationException>()),
    );
    verifyNever(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
        timeout: any(named: 'timeout'),
      ),
    );
  });

  test(
      'relanza ArticleSummaryGenerationException con AppErrorCode.timeout si el HttpClient da timeout',
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
      sut.summarizeArticle('Título', 'Contenido', language: 'es'),
      throwsA(
        isA<ArticleSummaryGenerationException>()
            .having((e) => e.code, 'code', AppErrorCode.timeout),
      ),
    );
    verify(
      () => mockObservabilityClient.captureException(any(), any()),
    ).called(1);
  });

  test(
      'relanza ArticleSummaryGenerationException con AppErrorCode.network si el HttpClient falla por red',
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
      sut.summarizeArticle('Título', 'Contenido', language: 'es'),
      throwsA(
        isA<ArticleSummaryGenerationException>()
            .having((e) => e.code, 'code', AppErrorCode.network),
      ),
    );
    verify(
      () => mockObservabilityClient.captureException(any(), any()),
    ).called(1);
  });
}
