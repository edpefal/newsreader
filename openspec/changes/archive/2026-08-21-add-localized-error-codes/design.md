## Context

Ver `proposal.md` - Why. Inventario completo de excepciones y mensajes hardcodeados relevados para este change (todo lo que hoy termina en un `Text`/`SnackBar` visible):

**Familia `AppException`** (`core/errors/app_exception.dart`), cada una construida en un único lugar salvo `ParseException` y `AccountDeletionException`:
- `NetworkException`/`TimeoutException` — siempre mensaje default, construidas en `core/network/http_package_client.dart`.
- `ParseException` — dos significados distintos según quién la lanza: `webfeed_feed_parser.dart` ("no encontramos un feed válido en esta URL") vs `xml_opml_parser.dart` ("el archivo no es un OPML válido", a veces con el mensaje de `XmlException` interpolado).
- `DuplicateSourceException`/`FeedDiscoveryException` — siempre mensaje default, en `add_source.dart`.
- `AccountDeletionException` — tres orígenes: sin sesión activa, error devuelto por el backend (`decoded['error']`, texto dinámico), o fallback genérico.
- `NotFoundException` — sin ningún call site hoy (código muerto); se le da código igual por completitud del enum, sin usarla en la práctica.

**Excepciones independientes** (mismo patrón, en sus propios módulos de `core/`):
- `AuthException` (`core/auth/`) — token de Google/Apple faltante, error nativo de Sign in with Apple (`e.message`, texto provisto por iOS, no traducible por nosotros), o catch-all (`e.toString()`).
- `EmailFeedGenerationException` (`core/email_feed/`) — sin sesión activa, respuesta inválida del backend, o catch-all.
- `SummaryGenerationException` (`core/ai/`) — sin artículos para resumir, sin sesión activa, respuesta inválida del backend, o catch-all.

**Fuera de alcance** (auditadas, confirmado que su `.message` nunca llega a la UI — `inbox_cubit.dart` las traga con `catch (_)` genérico antes de que su texto se use):
- `CloudSyncException`, `FeedSyncException`.

**Literales emitidos directo desde un Cubit, sin excepción de por medio:**
- `AddSourceCubit`: URL vacía, error inesperado genérico.
- `ImportOpmlCubit`: sin feeds en el archivo, error genérico al leer el archivo.
- `import_opml.dart` (`_validateSingle`): error de validación por feed individual (`OpmlFeedValidation.errorMessage`, dinámico por ítem — llega a la UI en `_ErrorFeedTile`).
- `SummariesCubit`: sin artículos nuevos hoy (`NoArticlesTodayException`, distinta de `SummaryGenerationException` pero mismo concepto), error genérico de generación.

## Goals / Non-Goals

**Goals:**
- Ningún mensaje de error visible para el usuario queda hardcodeado en un solo idioma.
- Un único enum de códigos de error, compartido entre todas las excepciones del proyecto (no un enum por módulo).
- Los casos genuinamente dinámicos (texto de error de un backend, mensaje nativo de un SDK) caen a un código genérico localizado, sin intentar traducir contenido arbitrario.

**Non-Goals:**
- No se agrega logging/reporting de errores (no existe hoy en el proyecto; agregarlo es un change aparte).
- No se traduce el contenido dinámico de terceros (mensajes de backend, excepciones nativas de SDKs).
- No se tocan `CloudSyncException`/`FeedSyncException` (ver Context — no impactan la UI hoy).
- No se re-evalúa ningún flujo de negocio; el comportamiento de éxito/fallo de cada operación no cambia, solo cómo se presenta el texto del error.

## Decisions

### 1. Un enum compartido `AppErrorCode`, no uno por excepción
Se agrega `core/errors/app_error_code.dart` con un solo enum usado por `AppException` y por las excepciones independientes (`AuthException`, `EmailFeedGenerationException`, `SummaryGenerationException`). Valores (agrupados por origen, no por excepción):

```
network, timeout, invalidFeedUrl, invalidOpmlFile, duplicateSource,
notFound, feedDiscoveryFailed, noActiveSession, accountDeletionFailed,
googleTokenMissing, appleTokenMissing, authProviderError,
emptyUrl, opmlNoFeedsFound, opmlFeedValidationFailed,
noArticlesToday, generationFailed, unknown
```

`noActiveSession` se reusa entre `AccountDeletionException`, `EmailFeedGenerationException` y `SummaryGenerationException` (las tres tienen exactamente ese caso). `generationFailed` se reusa entre resumen y generación de dirección de email (mismo concepto: "no pudimos completar la operación con el backend"). `unknown` es el catch-all final de cualquier excepción no anticipada.

**Alternativa considerada**: un enum por excepción (`AuthErrorCode`, `AppErrorCode`, `SummaryErrorCode`...), más fiel a que cada módulo de `core/` es independiente. Se descarta: multiplica el número de tipos sin necesidad real (los códigos no se cruzan entre módulos de forma confusa), y un único enum simplifica el mapeo a `AppLocalizations` a una sola función.

### 2. La resolución código → texto vive en `core/errors/`, no en cada widget
Se agrega una extensión `AppErrorCodeL10n` sobre `AppErrorCode` en el mismo archivo del enum (o uno adjunto, `core/errors/app_error_code_localizations.dart`), con un método `String localize(AppLocalizations l10n)`. Los widgets/Cubits que hoy hacen `Text(state.message)` pasan a hacer `Text(state.code.localize(AppLocalizations.of(context)))`. Esto mantiene un único lugar de mapeo, testeable sin levantar cada pantalla.

**Alternativa considerada**: un `switch` repetido en cada widget que muestra un error. Se descarta por duplicación — son ~8 lugares que necesitan exactamente la misma lógica de mapeo.

### 3. `ParseException` recibe el código en el constructor, no un default fijo
Hoy `ParseException([this.message = '...'])` tiene un único default que dos call sites (feed parser vs OPML parser) pisan con textos distintos. Pasa a `ParseException(this.code)` sin default — cada call site indica explícitamente `AppErrorCode.invalidFeedUrl` o `AppErrorCode.invalidOpmlFile`. Mismo criterio para `AccountDeletionException`: sin default, cada call site decide entre `noActiveSession` y `accountDeletionFailed`.

**Alternativa considerada**: mantener un default y solo permitir overridearlo. Se descarta: un default "adivinado" es exactamente el tipo de acoplamiento implícito que causó que `ParseException` tuviera dos significados mezclados hoy.

### 4. Contenido dinámico del backend/SDK: se descarta, no se intenta traducir
Cuando `decoded['error']` (backend) o `e.message`/`e.toString()` (SDK nativo o excepción no anticipada) es la única fuente de detalle, ese texto se descarta por completo — no se guarda en ningún campo del `AppException`/estado del Cubit — y se usa el código genérico correspondiente (`generationFailed`, `authProviderError`, `unknown`). No hay mecanismo de logging en el proyecto hoy para preservar ese detalle en otro lado (ver Non-Goals); agregar uno es un change aparte.

**Alternativa considerada**: guardar el texto original en un campo `technicalDetail` no mostrado en la UI principal, accesible solo si se agrega una futura pantalla de diagnóstico. Se descarta por ahora: no hay ningún consumidor de ese campo hoy (ni logging, ni pantalla de detalle), así que agregarlo sería código muerto especulativo.

### 5. `OpmlFeedValidation.errorMessage` (dominio) pasa a `errorCode: AppErrorCode?`
Es el único lugar donde un mensaje de error dinámico fluye desde una capa de dominio (`import_opml.dart`, el usecase) hasta un widget (`_ErrorFeedTile` en `import_opml_screen.dart`), pasando por el estado del Cubit (`OpmlFeedItem`). Se cambia el tipo en las tres capas a la vez, ya que es el mismo dato viajando sin transformación.

## Risks / Trade-offs

- **[Riesgo] Es un refactor transversal: toca ~15 archivos que definen excepciones/estados y ~8 widgets que los consumen.** Un error en alguno de esos puntos puede dejar un mensaje sin traducir sin que `flutter analyze` lo detecte (el tipo sigue siendo válido, solo cambia el contenido). → Mitigación: la tarea de verificación final incluye un grep de barrido buscando `\.message\b` remanente fuera de los archivos ya excluidos (`CloudSyncException`, `FeedSyncException`), y correr la suite completa de tests, que ya cubre buena parte de estos flujos.
- **[Riesgo] Perder el detalle técnico específico de un error (ej. el mensaje exacto de una `XmlException`) dificulta diagnosticar bugs reportados por usuarios.** → Mitigación: aceptado explícitamente (ver Decisión 4) — no hay mecanismo de logging en el proyecto para aprovechar ese detalle hoy; agregarlo es trabajo futuro, no bloqueante acá.
- **[Riesgo] `NotFoundException` queda con código pero sin ningún call site — trabajo sin payoff inmediato.** → Mitigación: es una sola línea (agregar el código al constructor existente), no vale la pena eliminar la clase en este change (fuera de alcance, no relacionado con i18n).

## Migration Plan

- Orden de implementación sugerido (ver `tasks.md`): (1) `AppErrorCode` + su mapeo a `AppLocalizations` + claves ARB nuevas en los 3 idiomas, (2) migrar `AppException` y subclases, (3) migrar las tres excepciones independientes (`AuthException`, `EmailFeedGenerationException`, `SummaryGenerationException`), (4) migrar los literales directos de Cubits (incluyendo `OpmlFeedValidation.errorMessage`), (5) actualizar cada Cubit/estado/widget consumidor y sus tests, (6) verificación final (barrido, `flutter analyze`, `flutter test`, prueba manual en los 3 idiomas).
- Rollback: revertir el commit; no hay migración de datos.
