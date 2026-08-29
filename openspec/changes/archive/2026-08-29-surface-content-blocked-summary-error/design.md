## Context

`ArticleSummarySheetContent` (`article_summary_bottom_sheet.dart`) no tiene un botón de "reintentar" explícito -- el estado `ArticleSummaryError(code)` solo muestra `code.localize(l10n)` como texto. "Invitar a reintentar" hoy es puramente el texto del mensaje (`errorGenerationFailed`: "Algo salió mal. Intenta de nuevo."), que el usuario puede accionar cerrando y volviendo a abrir el bottom sheet. `SummariesCubit`/`DailySummaryError` sigue el mismo patrón para el resumen diario. Por eso este change no toca la UI de ninguna de las dos pantallas -- alcanza con `AppErrorCode`s nuevos y su propio texto.

`GeminiArticleSummaryGenerator.summarizeArticle` y `GeminiSummaryGenerator.summarize` ya distinguen `decoded['error'] == 'ai_usage_limit_reached'` de cualquier otro error (ver `surface-summary-backend-errors`, archivado). El backend (`summarize-article/index.ts`) ya detecta el caso de texto vacío de Gemini y loguea `promptFeedback` (agregado en ese mismo change archivado) -- ahí es donde vive `blockReason`. Tanto `summarize-article` como `summarize-articles` rechazan por falta de suscripción activa con el mismo `JSON.stringify({ error: "Se requiere una suscripción activa" })` -- una oración fija en español, no un código machine-readable, a diferencia de `"ai_usage_limit_reached"`.

## Goals / Non-Goals

**Goals:**
- Que el backend distinga, en el `error` que devuelve, un bloqueo de contenido del proveedor de IA (`promptFeedback?.blockReason` presente) de cualquier otro fallo genérico, en `summarize-article`.
- Que el backend devuelva un código estable (no una oración) cuando rechaza por falta de suscripción activa, en ambas Edge Functions.
- Que el cliente mapee cada error específico a su propio `AppErrorCode`, con su propio texto en los 3 idiomas, sin implicar que reintentar la misma acción vaya a cambiar el resultado cuando no corresponde (bloqueo de contenido).

**Non-Goals:**
- No se agrega un botón de "reintentar" explícito a ninguna de las dos pantallas -- no existe hoy y está fuera de alcance rediseñar esa UI.
- No se investiga el bloqueo de contenido (`content_blocked`) para `GeminiSummaryGenerator`/`summarize-articles` -- agrupa varios artículos en un solo prompt, y no está claro qué artículo del batch lo causaría ni cómo comunicarlo. Solo se agrega `subscriptionRequired` ahí, que es un caso más simple (no depende de qué artículo).
- No se intenta ajustar `safetySettings` de la llamada a Gemini -- ya se confirmó que `PROHIBITED_CONTENT` no es una de las categorías configurables vía esa API.
- No se investiga por qué la suscripción de sandbox usada en las pruebas expiró entre la verificación local y la del backend -- es un comportamiento esperado de las suscripciones de sandbox de Apple (renuevan/expiran mucho más rápido que en producción real), no un bug de sincronización a arreglar.

## Decisions

- **El backend devuelve `{"error": "content_blocked"}`** (mismo patrón ya usado para `ai_usage_limit_reached`: una string plana en el campo `error`, sin exponer el `blockReason` crudo de Gemini al cliente) cuando `rawText` viene vacío y `geminiData?.promptFeedback?.blockReason` existe. Si el texto viene vacío por otra razón (sin `blockReason`), se mantiene la respuesta genérica actual (`"Respuesta vacía del modelo"`).
- **El backend devuelve `{"error": "subscription_required"}`** en vez de la oración fija actual, en el rechazo por falta de suscripción activa de ambas Edge Functions (`summarize-article` y `summarize-articles`) -- mismo criterio que `ai_usage_limit_reached`/`content_blocked`: un código estable, no texto humano, para que el cliente lo pueda distinguir sin parsear una oración en español.
- **Nuevos `AppErrorCode.contentBlocked` y `AppErrorCode.subscriptionRequired`**, agregados al enum existente (`core/errors/app_error_code.dart`) siguiendo el mismo patrón que `aiUsageLimitReached`: códigos específicos y accionables, no variantes de `generationFailed`.
- **`GeminiArticleSummaryGenerator.summarizeArticle` gana dos chequeos más** (`content_blocked` y `subscription_required`) en la misma cadena de `if` que ya distingue `ai_usage_limit_reached`, antes del fallback a `generationFailed`. **`GeminiSummaryGenerator.summarize` gana solo el de `subscription_required`.**
- **Textos de los mensajes** (a definir el nombre exacto de las claves en tasks): `contentBlocked` explica que ese artículo puntual no se puede resumir, sin verbo imperativo de reintentar (a diferencia de `errorGenerationFailed` que sí termina en "Intenta de nuevo."); `subscriptionRequired` explica que hace falta una suscripción activa, sin implicar que sea un error transitorio.

## Risks / Trade-offs

- [Gemini podría no siempre incluir `promptFeedback.blockReason` de forma consistente para todo tipo de bloqueo -- si en el futuro aparece un bloqueo con otra forma no cubierta por este chequeo, caería en el `generationFailed` genérico] → Aceptable: es exactamente el comportamiento actual (ya está cubierto como fallback), no es una regresión.
- [Cambiar el `error` de "Se requiere una suscripción activa" a `"subscription_required"` es un cambio de contrato entre backend y cliente -- si alguna vez se desplegara el backend nuevo sin el cliente nuevo (o viceversa), ese caso puntual caería en el `generationFailed` genérico en vez del mensaje específico] → Aceptable: no es una regresión funcional (sigue mostrando *un* error), y ambos lados se despliegan en la misma sesión de este change.
