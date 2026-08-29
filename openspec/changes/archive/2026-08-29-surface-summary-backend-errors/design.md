## Context

`GeminiArticleSummaryGenerator.summarizeArticle` y `GeminiSummaryGenerator.summarize` decodifican el body de `_httpClient.post(...)` y, si no encuentran `summary`/`mentions` válidos, revisan si `decoded['error'] == 'ai_usage_limit_reached'` para lanzar `AppErrorCode.aiUsageLimitReached`; en cualquier otro caso lanzan el mismo `AppErrorCode.generationFailed` sin importar cuál de los varios mensajes de error estructurado (`"Respuesta vacía del modelo"`, `"Respuesta inválida del modelo"`, `"No se pudo generar el resumen"`, `"Backend mal configurado"`, `"Body inválido"`, `"Se requiere title y content"`) vino realmente en `decoded['error']` -- ver `supabase/functions/summarize-article/index.ts`. `HttpPackageClient.post`/`get` (`core/network/http_package_client.dart`) no revisan el status code HTTP, así que todos esos casos (400/429/500/502) llegan al generator como si fueran una respuesta 200 con formato inesperado.

## Goals / Non-Goals

**Goals:**
- Que el mensaje de error real que devuelve el backend (`decoded['error']`) quede visible en Sentry cuando se lanza `AppErrorCode.generationFailed` por una respuesta sin `summary`/`mentions`.

**Non-Goals:**
- No cambiar `HttpPackageClient` para que revise status codes -- sería un cambio más grande (afecta todos los call sites de `HttpClient.get`/`post`, incluido feed fetching) y no hace falta para este fix puntual: el body ya trae `decoded['error']` con el mensaje real, alcanza con capturarlo antes de colapsar a `generationFailed`.
- No agregar un `AppErrorCode` nuevo ni cambiar lo que ve el usuario final -- sigue siendo el mismo estado de error genérico ya soportado por `article-summaries`/`daily-summaries`.

## Decisions

- **Usar `TelemetryClient.captureMessage` (no `captureException`) para reportar el error real.** No hay una excepción real que capturar en este punto -- es una respuesta HTTP con forma inesperada, no un `catch`. `captureMessage(String, {TelemetryLevel level})` ya existe en la interfaz y es la herramienta pensada para este caso (nivel `warning`, con el mensaje real del backend como texto).
- **Llamar `captureMessage` justo antes de lanzar `AppErrorCode.generationFailed`, no antes de `aiUsageLimitReached`.** El caso de `aiUsageLimitReached` ya es distinguible y accionable tal cual (código de error específico); agregarle un `captureMessage` sería ruido. El caso que hoy queda opaco es exactamente el que cae en `generationFailed`.
- **Incluir el mensaje crudo de `decoded['error']` (o `'sin mensaje'` si es null/no-string) en el texto del `captureMessage`.** Es la única pista real que trae el backend sobre la causa; pasarlo tal cual evita inventar categorías nuevas del lado del cliente.

## Risks / Trade-offs

- [`decoded['error']` podría no ser un `String` si el backend cambia su forma de respuesta] → Se castea de forma defensiva (`decoded['error']?.toString() ?? 'sin mensaje'`) para que el `captureMessage` nunca falle por un tipo inesperado.
