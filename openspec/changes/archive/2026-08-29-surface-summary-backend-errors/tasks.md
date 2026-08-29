## 1. Reportar el error real del backend

- [x] 1.1 En `GeminiArticleSummaryGenerator.summarizeArticle`, antes de lanzar `AppErrorCode.generationFailed` (cuando `decoded['error']` no es `'ai_usage_limit_reached'`), llamar `_observabilityClient.captureMessage` con el mensaje real (`decoded['error']?.toString() ?? 'sin mensaje'`) y `level: TelemetryLevel.warning`.
- [x] 1.2 Repetir 1.1 en `GeminiSummaryGenerator.summarize`.

## 2. Tests

- [x] 2.1 En `gemini_article_summary_generator_test.dart`, agregar un caso donde el backend responde `{"error": "Respuesta inválida del modelo"}` y verificar que se llama `captureMessage` con ese texto antes de lanzar `ArticleSummaryGenerationException(AppErrorCode.generationFailed)`.
- [x] 2.2 Repetir 2.1 en `gemini_summary_generator_test.dart` con `SummaryGenerationException`.
- [x] 2.3 Confirmar que el caso ya existente de `ai_usage_limit_reached` sigue pasando sin disparar `captureMessage` (no debe volverse ruidoso). Se agregó un test explícito para cada generator.

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` y `flutter test`. Ambos limpios (522 tests pasando). Se agregó `registerFallbackValue(TelemetryLevel.info)` en ambos test files -- faltaba para poder usar `any()`/`level: any(named: 'level')` en las verificaciones de `captureMessage` con mocktail.
- [x] 3.2 Validado en producción: al reintentar con un artículo de Substack que también falló, apareció **REEVO-PROD-5** ("summarize-article respondió sin summary/mentions: Respuesta vacía del modelo"), un issue de tipo `message`/`level: warning` separado del `generationFailed` genérico (REEVO-PROD-3) -- confirma que el `captureMessage` funciona y expone la causa real (Gemini devolvió una respuesta vacía, posiblemente bloqueo de safety filter o contenido excede el límite de tokens de entrada).

## 4. Logging del backend (hallazgo durante la verificación 3.2)

Revisando los logs de la Edge Function en el dashboard de Supabase para diagnosticar REEVO-PROD-5, se encontró que `summarize-article` no loguea nada en los tres branches de error de respuesta de Gemini (`rawText` vacío, `JSON.parse` inválido, `summary`/`mentions` con formato inesperado) -- solo hay `console.error` para el error de cuota (`check_and_record_ai_usage`) y para un status HTTP no-2xx de Gemini. Por eso no había ningún rastro server-side de la causa real (`finishReason`/`safetyRatings`) cuando Gemini responde 200 OK pero sin texto utilizable.

- [x] 4.1 Agregar `console.error` con `finishReason` y `safetyRatings` del primer candidate (si existen) en el branch de `rawText` vacío (línea ~321) de `supabase/functions/summarize-article/index.ts`.
- [x] 4.2 Agregar `console.error` con el `rawText` crudo (truncado) en el branch de `JSON.parse` inválido (línea ~331).
- [x] 4.3 Agregar `console.error` con el `parsed` decodificado en el branch de formato inesperado de `summary`/`mentions` (línea ~340).
- [x] 4.4 Confirmar con el usuario a qué proyecto(s) de Supabase desplegar (`reevo` prod y/o `reevo-dev`) antes de dar el change por terminado. Confirmado: ambos.
- [x] 4.5 Desplegado `summarize-article` a `reevo` (prod) y `reevo-dev` vía `supabase functions deploy`.
- [x] 4.6 Validado en el dashboard de Supabase (logs de la Edge Function): al reintentar, apareció `Gemini devolvió texto vacío. finishReason: undefined, safetyRatings: undefined` -- ambos `undefined` revela que `geminiData.candidates` viene vacío/ausente, no que un candidate se cortó. Eso apunta a un bloqueo del *prompt* completo (`promptFeedback.blockReason` de la API de Gemini), campo que no se estaba logueando. Se agregó `promptFeedback` al mismo `console.error` y se re-desplegó a `reevo` y `reevo-dev`.
- [x] 4.7 Confirmado en los logs: `promptFeedback: {"blockReason":"PROHIBITED_CONTENT"}`. Causa raíz real encontrada -- Gemini bloquea el prompt completo por su propio safety filter, clasificando el contenido del artículo (newsletter/Substack) como contenido prohibido. No es un bug de la app; es una decisión de moderación del modelo. Ver proposal.md para la discusión de si esto amerita un fix de producto aparte (fuera de alcance de este change).
