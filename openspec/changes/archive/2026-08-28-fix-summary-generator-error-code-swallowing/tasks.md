## 1. Fix error code passthrough

- [x] 1.1 En `lib/core/ai/gemini_article_summary_generator.dart`, agregar una cláusula `on AppException catch (e, st)` (importando `core/errors/app_exception.dart`) entre el `on ArticleSummaryGenerationException { rethrow; }` existente y el `catch (e, st)` genérico: reportar a `_observabilityClient.captureException(e, st)` y relanzar `ArticleSummaryGenerationException(e.code)` en vez de caer al `catch` genérico que fuerza `AppErrorCode.unknown`.
- [x] 1.2 Aplicar el mismo cambio en `lib/core/ai/gemini_summary_generator.dart` (cláusula `on AppException catch (e, st)` antes del `catch (e, st)` genérico, relanzando `SummaryGenerationException(e.code)`).

## 2. Tests

- [x] 2.1 Crear `test/unit/core/ai/gemini_article_summary_generator_test.dart` (no existe hoy) siguiendo el patrón de `gemini_summary_generator_test.dart` (mocktail para `HttpClient`/`AuthClient`/`ObservabilityClient`), cubriendo al menos el caso feliz y el de sesión sin token, y agregar un caso: cuando `HttpClient.post` lanza `TimeoutException`, `summarizeArticle` relanza `ArticleSummaryGenerationException(AppErrorCode.timeout)` (no `unknown`) y reporta la excepción original a observability.
- [x] 2.2 En `test/unit/core/ai/gemini_summary_generator_test.dart`, agregar un caso equivalente: `HttpClient.post` lanza `TimeoutException` → `summarize` relanza `SummaryGenerationException(AppErrorCode.timeout)`.
- [x] 2.3 En ambos archivos de test, agregar un caso análogo para `NetworkException` → `AppErrorCode.network`.

## 3. Verificación

- [x] 3.1 Correr `flutter test test/unit/core/ai/` y confirmar que todos los tests (nuevos y existentes) pasan.
- [x] 3.2 Correr `flutter analyze` y confirmar cero warnings.
