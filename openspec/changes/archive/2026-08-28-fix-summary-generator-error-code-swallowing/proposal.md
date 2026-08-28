## Why

Sentry issue [REEVO-PROD-3](https://reevo.sentry.io/issues/REEVO-PROD-3) (`ArticleSummaryGenerationException: AppErrorCode.unknown`) fired at the exact same moment as [REEVO-PROD-2](https://reevo.sentry.io/issues/REEVO-PROD-2) (`TimeoutException` in `HttpPackageClient.post`), same user, same trace window. `GeminiArticleSummaryGenerator.summarizeArticle`'s catch-all block reports the real exception to Sentry but then discards its type and rethrows a generic `AppErrorCode.unknown`, even though `AppErrorCode.timeout` already exists and is exactly what happened. This makes the Sentry issue for the wrapped exception useless for triage (it duplicates a vaguer version of an issue that already exists with the real cause), and shows the user a generic error message instead of "la solicitud tardó demasiado" when a specific one is available.

The sibling `GeminiSummaryGenerator.summarize` (used for the daily digest) has the identical catch-all pattern and the same bug, so it's included in scope.

## What Changes

- `GeminiArticleSummaryGenerator.summarizeArticle` and `GeminiSummaryGenerator.summarize` catch `AppException` (the sealed type both `NetworkException` and `TimeoutException` extend, see `core/errors/app_exception.dart`) before their generic `catch (e, st)`, and rethrow using the caught exception's own `code` instead of always falling back to `AppErrorCode.unknown`.
- The generic catch-all is preserved as a fallback for truly unanticipated errors (still mapped to `AppErrorCode.unknown`).

## Capabilities

No spec-level behavior changes: both `article-summaries` and `daily-summaries` already require "mostrar un estado de error distinguible" on AI call failure, which is satisfied today (just with a less specific code than available). This change only makes an existing, already-modeled error code (`timeout`/`network`) reach the user and Sentry instead of being collapsed into `unknown`. See `.openspec.yaml` (`skip_specs: true`).

## Impact

- `lib/core/ai/gemini_article_summary_generator.dart`
- `lib/core/ai/gemini_summary_generator.dart`
- Existing unit tests for both generators (add cases for `NetworkException`/`TimeoutException` passthrough).
