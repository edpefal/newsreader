## Context

Ver `proposal.md` para la motivación. Puntos de partida relevantes para el diseño:

- No existe ningún hook de error global hoy (`FlutterError.onError`, `PlatformDispatcher.instance.onError` no están seteados; no hay `runZonedGuarded` en `main.dart`).
- El patrón de abstracción de infraestructura ya está establecido (`HttpClient`, `FeedParser`, `AuthClient`, etc. en `core/`, implementación concreta registrada una sola vez en `core/di/injection.dart`).
- `AppConfig` ya separa credenciales dev/prod para Supabase vía `String.fromEnvironment('APP_ENV', ...)`; el mismo mecanismo aplica para el DSN de Sentry.
- `main.dart` ya tiene un listener de `authClient.authStateChanges` donde identifica/resetea al usuario ante Superwall — es el lugar natural para hacer lo mismo con observabilidad.
- El change `add-localized-error-codes` (ya archivado) dejó cada excepción de dominio con un `AppErrorCode`; ese código determina qué ve el usuario, pero no persiste el objeto de excepción original ni el stacktrace en ningún lado.

## Goals / Non-Goals

**Goals:**
- Reportar excepciones no manejadas (Flutter + Dart async) sin cambiar el comportamiento de crash de la plataforma.
- Reportar, sin cambiar el comportamiento visible, las excepciones que hoy se capturan y se descartan o se traducen a un `AppErrorCode`.
- Mantener la implementación de Sentry completamente detrás de `ObservabilityClient`: ningún archivo fuera de `core/observability/` y `core/di/injection.dart` importa `sentry_flutter`.
- Separar reportes de dev y prod usando dos proyectos de Sentry distintos (uno por DSN), igual que Supabase.
- No enviar PII (email, contenido de artículos) al proveedor.

**Non-Goals:**
- Performance tracing / traces de Sentry (`tracesSampleRate`) — se puede agregar después detrás de la misma abstracción, no es parte de este change.
- Analytics de producto (funnels, retención, dashboards de comportamiento) — `trackEvent` queda declarado en la interfaz pero sin implementación de negocio ni call sites; si más adelante hace falta analytics real, se cambia la implementación detrás de la abstracción.
- Session replay / breadcrumbs automáticos de navegación (Sentry los ofrece, pero requieren revisar qué pantallas exponen contenido de usuario antes de habilitarlos) — queda para un change futuro si se decide usar.
- Alertas, dashboards o configuración del lado de Sentry (proyectos, reglas de alerta) — es config externa, se documenta como prerequisito pero no es parte del código.

## Decisions

### 1. Forma de la abstracción

```dart
// core/observability/observability_client.dart
enum ObservabilityLevel { debug, info, warning, error, fatal }

abstract class ObservabilityClient {
  void captureException(Object error, StackTrace stackTrace, {Map<String, Object?>? context});
  void captureMessage(String message, {ObservabilityLevel level = ObservabilityLevel.info});
  void addBreadcrumb(String message, {String? category, Map<String, Object?>? data});
  void trackEvent(String name, {Map<String, Object?>? properties}); // sin call sites en este change
  void setUserId(String? userId);
}
```

`context`/`properties`/`data` son `Map<String, Object?>` genéricos — quien llama nunca importa un tipo de Sentry. La implementación (`SentryObservabilityClient`) es la única que traduce esto a `Sentry.captureException`, `Sentry.addBreadcrumb`, etc.

**Alternativa considerada**: exponer directamente `Sentry.captureException` envuelto en una función top-level en vez de una clase inyectable. Se descarta porque rompe el patrón ya establecido en el proyecto (todo lo demás se inyecta vía `get_it` y se abstrae en `core/`) y hace imposible testear Cubits/usecases que llamen a observabilidad sin tocar Sentry de verdad.

### 2. Sentry como proveedor, con `sentry_flutter`

Ver comparación completa en la conversación de exploración: SDK oficial de Flutter, free tier de 5k errores/mes, no arrastra un ecosistema completo (a diferencia de Firebase Crashlytics). `SentryFlutter.init` ya instala los hooks de `FlutterError.onError` y `PlatformDispatcher.instance.onError` internamente — no hace falta escribirlos a mano en `main.dart`, solo envolver `runApp` en el `appRunner` que pide `SentryFlutter.init`.

### 3. Dos proyectos Sentry (dev/prod), mismo patrón que Supabase

`AppConfig` suma:
```dart
static const String _devSentryDsn = '...';
static const String _prodSentryDsn = '...';
static const String sentryDsn = isProd ? _prodSentryDsn : _devSentryDsn;
```
Ambos DSN son públicos por diseño (Sentry los trata como client-side, análogos a la publishable key de Supabase o la API key de Superwall) — no son secretos, pero sí hace falta crear los dos proyectos en el dashboard de Sentry antes de mergear (paso manual, fuera del código).

`SentryFlutter.init` también setea `options.environment = AppConfig.isProd ? 'production' : 'development'` como metadata adicional dentro de cada proyecto (útil para filtrar por release/environment aunque ya estén en proyectos separados).

### 4. Qué instrumentar de los 19 `catch (_)`, y qué no

No todos los `catch (_)` representan una falla técnica interesante. Varios son control de flujo esperado sobre input del usuario (una URL de feed inválida, un archivo OPML mal formado) — reportarlos como error a Sentry los convertiría en ruido constante que quema el free tier sin aportar señal. La clasificación:

**Se reportan con `captureException` (fallas técnicas reales, no error de input del usuario):**

| Archivo | Por qué |
|---|---|
| `core/auth/supabase_auth_client.dart` (2 sitios) | Falla inesperada de un provider de auth (Google/Apple/Supabase), no input del usuario |
| `core/email_feed/supabase_email_feed_generator.dart` | Falla inesperada generando el email feed vía Edge Function |
| `core/ai/gemini_summary_generator.dart` | Falla inesperada del modelo/Edge Function de resúmenes |
| `features/auth/presentation/cubit/login_cubit.dart` | Fallback genuinamente inesperado (los casos conocidos ya se capturan antes) |
| `features/sources/presentation/cubit/add_source_cubit.dart` (2 sitios) | Fallback inesperado tras agregar fuente / generar email feed |
| `features/sources/domain/usecases/import_opml.dart:147` | Falla inesperada al importar un feed ya validado como OK (no es el parseo del archivo, es el alta en sí) |
| `features/summaries/presentation/cubit/summaries_cubit.dart` | Falla inesperada generando el resumen del día |
| `features/reader/domain/usecases/toggle_favorite.dart` | Best-effort de sync a la nube — no rompe la UX, pero si falla sistemáticamente hay que enterarse |
| `features/inbox/domain/usecases/mark_article_as_read.dart` | Ídem anterior |
| `features/inbox/presentation/cubit/inbox_cubit.dart:76` | Trigger de sync silencioso — ídem |
| `features/sources/presentation/cubit/source_detail_cubit.dart:48` | Ídem |
| `features/sources/presentation/cubit/import_opml_cubit.dart:43` | Fallback genuinamente inesperado del flujo de preview |

**No se reportan como excepción (son input del usuario / control de flujo esperado; en su lugar quedan como `catch (e, st)` para no perder la variable, pero sin llamar a `captureException` — o, donde aporte contexto, un `addBreadcrumb` de nivel bajo):**

| Archivo | Por qué |
|---|---|
| `core/opml/xml_opml_parser.dart:17` | Un archivo OPML mal formado es input del usuario, no un bug |
| `core/feed/webfeed_feed_parser.dart:13,16` | Intentar RSS y después Atom es control de flujo normal; solo fallar los dos es "esta URL no es un feed", esperado cuando el usuario pega cualquier URL |
| `core/feed/webfeed_feed_parser.dart:70` (`_parseDate`) | Una fecha con formato raro en un feed de terceros es rutina, ocurre todo el tiempo |
| `features/sources/domain/usecases/import_opml.dart:95` | Validación de una URL individual dentro de un OPML — mismo motivo que el parser de feeds |

En todos los casos, el cambio es mecánico y no toca el `AppErrorCode`/comportamiento ya existente: donde se decide reportar, se agrega una línea de `captureException` antes de la lógica actual; donde no, el `catch (_)` puede quedar como está o pasar a `catch (e, st)` sin uso si hace falta para claridad, pero no se le agrega ninguna llamada a Sentry.

### 5. Privacidad: nunca mandar email ni contenido de artículos

`setUserId` recibe únicamente el `userId` de Supabase (mismo id que ya usa `SubscriptionStatusProvider.identify`), nunca el email. `sendDefaultPii` de Sentry queda explícitamente en `false` (ya es el default del SDK, se declara igual para que quede documentado). Ningún `context`/`data` pasado a `captureException`/`addBreadcrumb` debe incluir el `contentHtml` de un artículo ni el email del usuario — se listará como regla a seguir en cada tarea de instrumentación.

## Risks / Trade-offs

- **[Riesgo] Quemar el free tier de Sentry (5k errores/mes) si algún catch-all se dispara en loop** → Mitigación: la clasificación de la sección anterior evita instrumentar los casos de alto volumen (parseo de feeds de terceros, validación de OPML). Si en el futuro un evento reportado resulta ruidoso, se ajusta ese sitio puntual sin tocar la abstracción.
- **[Riesgo] Fuga accidental de PII en `context`/`breadcrumb`** → Mitigación: regla explícita (sección 5) + code review de cada tarea de instrumentación revisa que no se pase `contentHtml` ni email.
- **[Riesgo] DSN de prod termina hardcodeado igual que el de Supabase hoy (visible en el repo)** → Aceptado: es el mismo trade-off que ya existe con las credenciales de Supabase en `AppConfig` (son client-side por diseño, no secretas). No se introduce un mecanismo nuevo de secret management en este change.
- **[Trade-off] No hay performance tracing ni session replay en este change** → Aceptado explícitamente como Non-Goal; se agrega después si hace falta, sin romper la abstracción.
