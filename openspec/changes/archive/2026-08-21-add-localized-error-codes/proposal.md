## Why

Desde el Change 1 (`add-i18n-infra-neutral-spanish`), toda la app usa `AppLocalizations` para su texto de UI — excepto los mensajes de error. Hoy `AppException` y varias otras clases de excepción (`AuthException`, `EmailFeedGenerationException`, `SummaryGenerationException`) cargan el texto humano hardcodeado en español directamente en el constructor, y ese texto viaja intacto hasta un `SnackBar`/`Text` sin pasar por traducción. Resultado: un usuario con la app en inglés o francés puede ver toda la interfaz en su idioma, pero un error de red, un feed inválido, o una fuente duplicada le aparece en español. Esto quedó documentado como deuda explícita en `CLAUDE.md` desde el Change 1, con la solución ya acordada: las excepciones dejan de cargar texto, pasan a ser identificables por código, y la traducción ocurre recién en la capa de presentación.

## What Changes

- Se introduce `AppErrorCode`, un enum compartido en `core/errors/` que identifica cada escenario de error conocido de la app (red, timeout, feed inválido, OPML inválido, fuente duplicada, sesión requerida, etc.), más un mapeo `AppErrorCode → AppLocalizations` que se resuelve en la capa de presentación.
- `AppException` y sus subclases (`NetworkException`, `TimeoutException`, `ParseException`, `DuplicateSourceException`, `NotFoundException`, `FeedDiscoveryException`, `AccountDeletionException`) dejan de cargar un `String message` y pasan a cargar un `AppErrorCode code`.
- `AuthException`, `EmailFeedGenerationException`, `SummaryGenerationException` (excepciones independientes de `AppException`, en `core/auth/`, `core/email_feed/`, `core/ai/`) reciben el mismo tratamiento: `code` en vez de `message`.
- Los estados de Cubit que hoy exponen `String message`/`errorMessage` (`AddSourceError`, `AddSourceFeedDiscoveryFailed`, `ImportOpmlError`, `OpmlFeedItem.errorMessage`, `LoginError`, `SummaryGenerationError`) pasan a exponer `AppErrorCode code`; las pantallas que los consumen resuelven el texto localizado recién al renderizar.
- Los mensajes que hoy se emiten como literales directamente desde un Cubit (sin excepción de por medio — validación de URL vacía, "ocurrió un error inesperado", "no se encontraron feeds", etc.) también pasan a un `AppErrorCode`.
- De paso, corrige el último voseo que sobrevivió al Change 1 porque estaba en esta zona explícitamente fuera de alcance (`"Intentá de nuevo"` en `summaries_cubit.dart` y `delete_account.dart`).
- **Fuera de alcance explícito**: `CloudSyncException` y `FeedSyncException` no se tocan — se auditó su uso y hoy se capturan genéricamente (`catch (_)`) en `inbox_cubit.dart` sin que su `.message` llegue nunca a la UI; convertirlas no arregla ningún bug visible. Queda como nota para una limpieza futura, no bloqueante acá.
- **Fuera de alcance explícito**: contenido de errores devueltos dinámicamente por el backend (`decoded['error']` en las Edge Functions de Supabase) no se traduce — cae al código de error genérico correspondiente; traducir texto arbitrario generado por un backend está fuera del alcance de este change.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `app-localization`: se agrega un nuevo requisito — los mensajes de error visibles para el usuario (red, validación, fallas de fuentes/feeds/cuenta) también se muestran en el idioma activo de la app, no solo el texto estático de UI.

## Impact

- **Código nuevo**: `core/errors/app_error_code.dart` (enum) y su mapeo a `AppLocalizations`.
- **Código afectado**: `core/errors/app_exception.dart`, `core/auth/auth_client.dart` + `supabase_auth_client.dart`, `core/email_feed/email_feed_generator.dart` + `supabase_email_feed_generator.dart`, `core/ai/summary_generator.dart` + `gemini_summary_generator.dart`, `core/opml/xml_opml_parser.dart`, `core/feed/webfeed_feed_parser.dart`, `features/sources/domain/usecases/add_source.dart` + `import_opml.dart`, `features/account/domain/usecases/delete_account.dart`, y las Cubits/estados/pantallas de Auth, Fuentes (agregar/importar OPML) y Resúmenes que hoy muestran estos mensajes.
- **Nuevas claves ARB**: ~20 claves nuevas (`error*`) en `app_en.arb`/`app_es.arb`/`app_fr.arb`, cubiertas automáticamente por los tests de regresión ya existentes (anti-voseo, completitud de francés).
- **Sin cambios de datos**: no afecta modelos de Hive ni contratos de red — es una reestructuración de cómo se identifica y presenta un error, no de qué errores existen.
