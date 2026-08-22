## 1. Prerequisito externo (manual, fuera del código)

- [x] 1.1 Crear dos proyectos en Sentry (uno dev, uno prod) para la plataforma Flutter/Dart y obtener sus DSN

## 2. Abstracción y config

- [x] 2.1 Agregar `sentry_flutter` a `pubspec.yaml`
- [x] 2.2 Crear `core/observability/observability_client.dart` con la interfaz `ObservabilityClient` y `ObservabilityLevel` (según `design.md` sección 1)
- [x] 2.3 Crear `core/observability/sentry_observability_client.dart` implementando `ObservabilityClient` sobre `sentry_flutter`, con `sendDefaultPii: false`
- [x] 2.4 Agregar `_devSentryDsn`/`_prodSentryDsn`/`sentryDsn` a `core/config/app_config.dart`, mismo patrón que las credenciales de Supabase
- [x] 2.5 Registrar `ObservabilityClient` en `core/di/injection.dart` (único lugar que instancia `SentryObservabilityClient`)

## 3. Inicialización y ciclo de vida

- [x] 3.1 `main.dart`: envolver el arranque de la app en `SentryFlutter.init` (DSN desde `AppConfig.sentryDsn`, `environment` según `AppConfig.isProd`), moviendo el `runApp(...)` actual al `appRunner`
- [x] 3.2 `main.dart`: en el listener existente de `authClient.authStateChanges`, llamar `observabilityClient.setUserId(userId)` / `setUserId(null)` en el mismo lugar donde ya se identifica/resetea ante Superwall
- [x] 3.3 Test: verificar (widget o unit, según corresponda) que `setUserId` se llama con el id correcto al iniciar sesión y con `null` al cerrar sesión/eliminar cuenta

## 4. Instrumentar los `catch (_)` que reportan a observabilidad

- [x] 4.1 `core/auth/supabase_auth_client.dart` (2 sitios): `catch (e, st)` + `captureException(e, st)` antes de lanzar `AuthException(AppErrorCode.unknown)`
- [x] 4.2 `core/email_feed/supabase_email_feed_generator.dart`: ídem con `EmailFeedGenerationException(AppErrorCode.unknown)`
- [x] 4.3 `core/ai/gemini_summary_generator.dart`: ídem con `SummaryGenerationException(AppErrorCode.unknown)`
- [x] 4.4 `features/auth/presentation/cubit/login_cubit.dart`: ídem antes de `emit(const LoginError(AppErrorCode.unknown))`
- [x] 4.5 `features/sources/presentation/cubit/add_source_cubit.dart` (2 sitios): ídem antes de `emit(const AddSourceError(AppErrorCode.unknown))`
- [x] 4.6 `features/sources/domain/usecases/import_opml.dart:147` (`execute`, no el de validación por feed): ídem antes de `return _ImportFailure(url)`
- [x] 4.7 `features/summaries/presentation/cubit/summaries_cubit.dart`: ídem en el catch-all de `generateTodaySummary`
- [x] 4.8 `features/reader/domain/usecases/toggle_favorite.dart`: ídem en `_tryPushFavoriteState`, conservando el comportamiento best-effort (no relanzar)
- [x] 4.9 `features/inbox/domain/usecases/mark_article_as_read.dart`: ídem en `_tryPushReadState`
- [x] 4.10 `features/inbox/presentation/cubit/inbox_cubit.dart:76`: ídem en el trigger de sync silencioso
- [x] 4.11 `features/sources/presentation/cubit/source_detail_cubit.dart:48`: ídem
- [x] 4.12 `features/sources/presentation/cubit/import_opml_cubit.dart:43`: ídem antes de `emit(const ImportOpmlError(AppErrorCode.invalidOpmlFile))`
- [x] 4.13 Revisar los 4 `catch (_)` que **no** se instrumentan (`xml_opml_parser.dart:17`, `webfeed_feed_parser.dart:13,16,70`, `import_opml.dart:95`) y dejar un comentario breve explicando por qué se excluyen a propósito (según `design.md` sección 4), para que no se agreguen por error en el futuro

## 5. Tests

- [x] 5.1 Fake/mock de `ObservabilityClient` reutilizable en tests (`test/support/` o similar) para los Cubits/usecases que ahora lo reciben
- [x] 5.2 Actualizar los tests existentes de los Cubits/usecases tocados en la sección 4 que instancian su clase directamente (agregar el mock/fake como dependencia nueva)
- [x] 5.3 Unit test de `SentryObservabilityClient`: verificar que `setUserId(null)` no incluye email ni PII, y que los métodos delegan correctamente a la API de `sentry_flutter` (con el SDK en modo test/mock)

## 6. Verificación final

- [x] 6.1 Correr `flutter analyze` y resolver cualquier warning
- [x] 6.2 Correr `flutter test` (unit + widget) y confirmar que todo pasa (único fallo: `localized_date_formatter_test.dart` "muestra hora HH:mm para hoy", preexistente y no relacionado — falla por falta de zero-padding en horas de un dígito, ej. corrido a las 7:09am; no lo toca este change)
- [x] 6.3 Probar manualmente: forzar una excepción no manejada y un error de los instrumentados en la sección 4 con `APP_ENV=dev`, confirmar que aparecen en el proyecto Sentry de dev (no en el de prod)
