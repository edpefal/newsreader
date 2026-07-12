import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai/gemini_summary_generator.dart';
import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/network/http_client.dart';

class MockHttpClient extends Mock implements HttpClient {}

void main() {
  late MockHttpClient mockHttpClient;
  late GeminiSummaryGenerator sut;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    sut = GeminiSummaryGenerator(mockHttpClient);
  });

  final tArticles = [
    (title: 'Título 1', excerpt: 'Extracto 1', sourceName: 'Fuente A'),
    (title: 'Título 2', excerpt: 'Extracto 2', sourceName: 'Fuente B'),
  ];

  test('lanza SummaryGenerationException si la lista está vacía', () {
    expect(sut.summarize([]), throwsA(isA<SummaryGenerationException>()));
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
      ),
    ).thenAnswer((_) async => '{"summary": "Resumen generado"}');

    final result = await sut.summarize(tArticles);

    expect(result, 'Resumen generado');
  });

  test('lanza SummaryGenerationException si el backend responde con error', () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((_) async => '{"error": "Backend mal configurado"}');

    expect(sut.summarize(tArticles), throwsA(isA<SummaryGenerationException>()));
  });

  test('lanza SummaryGenerationException si falla la request HTTP', () async {
    when(
      () => mockHttpClient.post(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenThrow(const NetworkException());

    expect(sut.summarize(tArticles), throwsA(isA<SummaryGenerationException>()));
  });
}
