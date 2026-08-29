## Why

Sentry issue [REEVO-PROD-3](https://reevo.sentry.io/issues/REEVO-PROD-3) (`ArticleSummaryGenerationException: AppErrorCode.generationFailed`) volvió a dispararse -- esta vez al pedir el resumen de un artículo tipo webview importado con Kill the Newsletter. `HttpPackageClient.post`/`get` (`lib/core/network/http_package_client.dart`) nunca revisan el status code de la respuesta HTTP: devuelven `response.body` sin importar si el backend contestó 200, 400, 429, 500 o 502. Como consecuencia, `GeminiArticleSummaryGenerator.summarizeArticle` y `GeminiSummaryGenerator.summarize` reciben el body de *cualquier* error estructurado que devuelve `summarize-article`/`summarize-articles` (`"Respuesta vacía del modelo"`, `"Respuesta inválida del modelo"`, `"No se pudo generar el resumen"`, `"Backend mal configurado"`, etc.) y, al no encontrar `summary`/`mentions`, todos esos casos distintos colapsan en el mismo `AppErrorCode.generationFailed` sin registrar la causa real -- el Sentry issue queda sin ninguna pista de qué falló realmente en el backend.

Es el mismo problema de fondo que se corrigió ayer para timeout/red (`fix-summary-generator-error-code-swallowing`), pero aplicado a los errores estructurados que el propio backend ya reporta con un mensaje específico.

## What Changes

- Antes de lanzar `AppErrorCode.generationFailed` por una respuesta sin `summary`/`mentions` válidos, `GeminiArticleSummaryGenerator.summarizeArticle` y `GeminiSummaryGenerator.summarize` registran vía `TelemetryClient.captureMessage` el mensaje de error real que vino en el body (`decoded['error']`), para que el Sentry issue muestre la causa concreta en vez de quedar opaco.
- El mensaje que ve el usuario final no cambia (sigue siendo el genérico de `AppErrorCode.generationFailed`); esto es una mejora de diagnosticabilidad, no de UX.

## Capabilities

No hay cambio de comportamiento a nivel de spec: `article-summaries` y `daily-summaries` ya requieren mostrar un estado de error distinguible ante un fallo de IA, y eso se sigue cumpliendo igual (mismo código de error visible al usuario). Este change solo agrega contexto de diagnóstico interno que no estaba. Ver `.openspec.yaml` (`skip_specs: true`).

## Impact

- `lib/core/ai/gemini_article_summary_generator.dart`
- `lib/core/ai/gemini_summary_generator.dart`
- Tests existentes de ambos generators (agregar casos que verifiquen el `captureMessage` cuando el backend devuelve un `error` estructurado distinto de `ai_usage_limit_reached`).
- `supabase/functions/summarize-article/index.ts`: se agregó `console.error` en los tres branches donde la respuesta de Gemini no trae `summary`/`mentions` utilizables (texto vacío, JSON inválido, formato inesperado), ya que ninguno de los tres logueaba nada -- hallazgo hecho al validar el fix del cliente en producción (REEVO-PROD-5) y no poder ver la causa real (`finishReason`/`safetyRatings`/`promptFeedback`) del lado del backend. Desplegado a `reevo` (prod) y `reevo-dev`.

Con el logging nuevo se confirmó la causa raíz real de REEVO-PROD-5 para los dos artículos de prueba (uno importado con Kill the Newsletter, otro de Substack): `promptFeedback: {"blockReason":"PROHIBITED_CONTENT"}` -- el safety filter de Gemini bloquea el prompt completo, clasificando el contenido del newsletter como contenido prohibido. No es un bug de la app; es una decisión de moderación del modelo, y queda fuera de alcance de este change decidir si conviene ajustar `safetySettings` en la llamada a Gemini (fix de producto aparte, con trade-offs de moderación que ameritan su propia conversación).
