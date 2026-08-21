## 1. `AppErrorCode` y su localización

- [x] 1.1 Crear `core/errors/app_error_code.dart` con el enum `AppErrorCode` (los 18 valores listados en `design.md`)
- [x] 1.2 Crear la extensión `AppErrorCodeL10n.localize(AppLocalizations)` que mapea cada valor a una clave de `AppLocalizations` — `opmlFeedValidationFailed` reusa la clave `sourcesFeedValidationFailed` ya agregada en el Change 1 (mismo texto exacto) en vez de duplicarla
- [x] 1.3 Agregar las claves `error*` correspondientes a `app_en.arb`, `app_es.arb` (neutro, sin voseo) y `app_fr.arb` (francés real, no placeholder), y correr `flutter gen-l10n` — 17 claves nuevas (una menos que los 18 códigos, por la reutilización de 1.2)
- [x] 1.4 Widget/unit test: cada valor de `AppErrorCode` resuelve a un string no vacío en los 3 idiomas (evita un `case` faltante en el mapeo)

## 2. Migrar `AppException` y subclases

- [x] 2.1 `core/errors/app_exception.dart`: cambiar `message: String` por `code: AppErrorCode` en `AppException` y sus 7 subclases; `ParseException` y `AccountDeletionException` sin default (cada call site decide)
- [x] 2.2 Actualizar call sites: `core/network/http_package_client.dart` (`NetworkException`/`TimeoutException` — no necesitaron cambios, ya no tenían argumentos), `core/feed/webfeed_feed_parser.dart` (`ParseException(AppErrorCode.invalidFeedUrl)`), `core/opml/xml_opml_parser.dart` (`ParseException(AppErrorCode.invalidOpmlFile)`, descartando el detalle de `XmlException` — de paso se simplificaron los dos `catch` a uno solo, ya lanzaban lo mismo), `features/sources/domain/usecases/add_source.dart` (`DuplicateSourceException`/`FeedDiscoveryException` sin cambios, ya no tenían argumentos), `features/account/domain/usecases/delete_account.dart` (`AccountDeletionException` con `noActiveSession` o `accountDeletionFailed`, descartando `decoded['error']`)

## 3. Migrar excepciones independientes

- [x] 3.1 `core/auth/auth_client.dart` + `supabase_auth_client.dart`: `AuthException` con `code` (`googleTokenMissing`, `appleTokenMissing`, `authProviderError` para el error nativo de Sign in with Apple, `unknown` para el catch-all)
- [x] 3.2 `core/email_feed/email_feed_generator.dart` + `supabase_email_feed_generator.dart`: `EmailFeedGenerationException` con `code` (`noActiveSession`, `generationFailed`, `unknown`)
- [x] 3.3 `core/ai/summary_generator.dart` + `gemini_summary_generator.dart`: `SummaryGenerationException` con `code` (`noArticlesToday`, `noActiveSession`, `generationFailed`, `unknown`)

## 4. Migrar literales directos de Cubits

- [x] 4.1 `AddSourceCubit`: URL vacía → `AppErrorCode.emptyUrl`; catch-all → `AppErrorCode.unknown` (junto con `AddSourceState`, tarea 5.1, en el mismo archivo `part`)
- [x] 4.2 `ImportOpmlCubit`: sin feeds en el archivo → `AppErrorCode.opmlNoFeedsFound`; catch-all → `AppErrorCode.invalidOpmlFile` (junto con `ImportOpmlState`/`OpmlFeedItem`, tarea 5.2)
- [x] 4.3 `features/sources/domain/usecases/import_opml.dart`: `OpmlFeedValidation.errorMessage: String?` → `errorCode: AppErrorCode?` (catch-all por feed individual → `AppErrorCode.opmlFeedValidationFailed`)
- [x] 4.4 `SummariesCubit`: `NoArticlesTodayException` → `AppErrorCode.noArticlesToday`; catch-all → `AppErrorCode.generationFailed` (junto con `SummariesState`, tarea 5.4)

## 5. Actualizar estados de Cubit, pantallas y sus tests

- [x] 5.1 `AddSourceState` (`AddSourceError`, `AddSourceFeedDiscoveryFailed`): `message`/`errorMessage` → `code: AppErrorCode`; actualizar `add_source_screen.dart` para resolver el texto con `AppLocalizations.of(context)` al renderizar; actualizar `add_source_screen_test.dart`
- [x] 5.2 `ImportOpmlState` (`ImportOpmlError`) y `OpmlFeedItem`: `message`/`errorMessage` → `code`; actualizar `import_opml_screen.dart` (`_ErrorView`, `_ErrorFeedTile`); actualizar `import_opml_screen_test.dart`
- [x] 5.3 `LoginState` (`LoginError`): `message` → `code`; actualizar `login_screen.dart`; agregar/actualizar test si existe
- [x] 5.4 `SummariesState` (`SummaryGenerationError`): `message` → `code`; actualizar `summaries_screen.dart`; actualizar `summaries_screen_test.dart`
- [x] 5.5 `lib/presentation/app/router.dart` (`_exportUserData`, `_confirmDeleteAccount`/`_deleteAccount`): resolver `AppErrorCode` en vez de `e.message` en los `SnackBar`

## 6. Verificación final

- [x] 6.1 Grep de barrido: confirmar que no queda ningún `\.message\b` de excepción llegando a un `Text`/`SnackBar` fuera de `CloudSyncException`/`FeedSyncException` (explícitamente fuera de alcance)
- [x] 6.2 Correr `flutter analyze` y resolver cualquier warning
- [x] 6.3 Correr `flutter test` (unit + widget) y confirmar que todo pasa
- [x] 6.4 Probar manualmente en simulador: forzar al menos un error (ej. agregar una URL que no sea un feed válido, o dejar el campo vacío) con el dispositivo en inglés y en francés, confirmar que el mensaje aparece en ese idioma
