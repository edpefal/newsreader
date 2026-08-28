## Context

Both `GeminiArticleSummaryGenerator.summarizeArticle` and `GeminiSummaryGenerator.summarize` follow the same shape:

```dart
try {
  ... _httpClient.post(...) ...
  ... parse response, throw *GenerationException(AppErrorCode.generationFailed/aiUsageLimitReached) on bad payload ...
} on <TheirOwnGenerationException> {
  rethrow;
} catch (e, st) {
  _observabilityClient.captureException(e, st);
  throw const <TheirOwnGenerationException>(AppErrorCode.unknown);
}
```

`HttpClient` (see `core/network/http_client.dart` doc comments) throws `NetworkException` on connection failure and `TimeoutException` on timeout — both defined in `core/errors/app_exception.dart` as subclasses of sealed `AppException`, each already carrying the matching `AppErrorCode` (`network` / `timeout`). The generic `catch (e, st)` currently catches these too and discards that code, always emitting `AppErrorCode.unknown`. `core/feed/supabase_feed_sync_trigger.dart` shows the established pattern of catching `NetworkException`/`TimeoutException` explicitly instead of falling into a generic catch.

## Goals / Non-Goals

**Goals:**
- Preserve the specific `AppErrorCode` (`timeout`, `network`) when the underlying failure is an `AppException`, instead of collapsing it to `unknown`.
- Keep behavior identical for genuinely unanticipated errors (still `unknown`, still reported to Sentry).

**Non-Goals:**
- Not changing what gets reported to Sentry or how (both the generator's `captureException(e, st)` and the cubit's `captureException(e, st)` stay as-is; that dual-reporting pattern already exists elsewhere in the codebase — e.g. `summaries_cubit.dart` — and is out of scope here).
- Not adding new `AppErrorCode` values; `timeout` and `network` already exist and are already localized (`app_error_code_localizations.dart`).

## Decisions

- **Catch `AppException` and rethrow with `e.code`, rather than enumerating `NetworkException`/`TimeoutException` separately.** Both generators only need to pass the code through; matching on the sealed base type is simpler than duplicating two `on X` clauses per file and stays correct if another `AppException` subtype ever surfaces from `HttpClient` in the future. Alternative considered: mirror `supabase_feed_sync_trigger.dart`'s two explicit `on NetworkException` / `on TimeoutException` clauses — rejected here because that file needs different *handling* per type (both currently return the same result, but it documents intent to diverge later), whereas both summary generators want identical handling (rethrow with the exception's own code), making the shared-base-type catch strictly simpler with no loss of clarity.
- **Place the new `on AppException catch (e)` clause between the existing `on <FooGenerationException> { rethrow; }` and the generic `catch (e, st)`.** Order matters: the existing generation-exception rethrow must stay first (those are already correctly typed), the new `AppException` clause comes next, and the generic catch remains last as the true fallback.

## Risks / Trade-offs

- [`AppException`'s other subtypes (`ParseException`, `DuplicateSourceException`, `NotFoundException`, `FeedDiscoveryException`, `AccountDeletionException`) are not expected from `HttpClient.post` or `jsonDecode`, but the generic `on AppException` clause would also pass their codes through if one ever leaked in] → Acceptable: passing through a more specific existing `AppErrorCode` is strictly better than collapsing to `unknown` even in that unlikely case, and none of those codes are misleading in a "summary generation failed" context.
