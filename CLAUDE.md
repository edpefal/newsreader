# Reevo — Instrucciones para Claude

## Comunicación con el usuario

Dirigirse al usuario siempre en **español latinoamericano neutro, con tuteo** ("tienes", "puedes", "avísame", "aquí"), nunca en voseo rioplatense/argentino ("tenés", "podés", "avisame", "acá"). Aplica a toda respuesta conversacional de Claude en el chat, sin excepción.

## Comandos esenciales

```bash
flutter pub get                          # instalar dependencias
flutter run                              # correr la app (APP_ENV=dev por defecto → reevo-dev)
flutter run --dart-define=APP_ENV=prod   # solo si alguien lo pide: apunta a prod (reevo)
flutter test                             # correr todos los tests
flutter test test/unit/                  # solo unit tests
flutter test test/widget/                # solo widget tests
flutter analyze                          # lint (correr antes de considerar algo listo)
dart run build_runner build              # regenerar TypeAdapters de Hive CE
dart run build_runner build --delete-conflicting-outputs  # si hay conflictos
flutter gen-l10n                         # regenerar AppLocalizations tras tocar lib/l10n/*.arb
(cd supabase/functions/<nombre> && deno test --allow-env)  # tests de una Edge Function puntual
```

`deno test` sin `--allow-env` falla en funciones que leen alguna variable de entorno en el código bajo test (ej. `enrich-mentions` lee `GOOGLE_BOOKS_API_KEY`) — el `PermissionDenied` suele quedar atrapado por un `try/catch` interno y aparece como una aserción fallida random, no como un error de permisos obvio. Correr siempre con `--allow-env`.

Correr `flutter analyze` después de cualquier cambio de código. No dejar warnings sin resolver.

## Proyectos de Supabase

Existen dos proyectos de Supabase, ambos bajo la misma organización:

| Proyecto | Reference ID | Uso |
|----------|--------------|-----|
| `reevo` | `avyaxzhdilhufyimrzzb` | Producción — es el que queda linkeado por defecto en el repo (`supabase/.temp/project-ref`) |
| `reevo-dev` | `xgwnxhpdcrghrtdbrmpn` | Desarrollo |

Al desplegar una Edge Function (`supabase functions deploy <nombre>`), por defecto solo se despliega al proyecto linkeado (`reevo`, prod). Para desplegar también a `reevo-dev`, agregar `--project-ref xgwnxhpdcrghrtdbrmpn` sin cambiar el link del repo. Antes de dar por terminado un cambio de Edge Function, confirmar con el usuario a cuál(es) de los dos proyectos hay que desplegarlo — no asumir que solo uno basta.

### Edge Functions (`supabase/functions/`)

| Función | Qué hace |
|---------|----------|
| `sync-feeds` | Fetch y parseo de RSS/Atom del lado del servidor (también por cron en modo background) |
| `generate-daily-summaries` | Genera el resumen diario de cada usuario elegible, sin acción del usuario (service_role) |
| `summarize-article` | Proxy a Gemini: resumen de un artículo + menciones |
| `enrich-mentions` | Proxy a Google Books / iTunes Search para enriquecer menciones (requiere `GOOGLE_BOOKS_API_KEY`) |
| `create-feed`, `feed`, `inbound-email` | Feeds generados a partir de emails (dirección única, feed RSS, webhook de entrada) |
| `delete-account` | Borra la cuenta y sus datos |
| `superwall-webhook` | Eventos de suscripción de Superwall |

Las migraciones se aplican con `apply_migration` (MCP de Supabase), no con `supabase db push`: las versiones del repo y de Supabase están desfasadas desde 2026-09-16 y `db push` reaplicaría migraciones viejas.

### Cuentas de Gemini (dev vs prod)

Los proyectos `reevo` y `reevo-dev` usan cuentas de Google AI/Gemini **separadas** para el `GEMINI_API_KEY` de las Edge Functions que llaman a Gemini (`summarize-article`, `summarize-articles`). Solo la de **prod (`reevo`) tiene billing habilitado** — no está sujeta al límite del free tier de Gemini (20 requests/día). La de dev sigue en el free tier, así que features que dependan de una cuota alta de requests pueden funcionar en prod y toparse con el límite en dev. Al diseñar un feature de IA nuevo o pensar en un free tier para el usuario final, no asumir que el límite de 20/día del free tier de Gemini aplica en prod.

### Orden de despliegue: servidor y clientes ya publicados

Un recurso del servidor que consultan clientes ya publicados (tabla, columna, función RPC, Edge Function, endpoint) **no se elimina ni se cambia de forma incompatible** hasta que la versión de la app que ya no depende de él esté **disponible en la App Store y adoptada** — no basta con que esté en TestFlight. Una app instalada no se actualiza sola de inmediato, y los usuarios nuevos pueden recibir la versión anterior durante días tras publicar la nueva.

Antes de aplicar una migración o desplegar una Edge Function que quite o cambie algo así:

1. Confirmar en App Store Connect que la versión sin la dependencia está en `READY_FOR_DISTRIBUTION` (`app-store-connect apps app-store-versions <app-id>`).
2. Revisar en PostHog (`$app_version` de `screen_view`) y en Sentry quién sigue en versiones anteriores y si tiene sesión iniciada.
3. Si todavía hay clientes anteriores con sesión, mantener una compatibilidad temporal (por ejemplo, una tabla vacía) con criterio de retiro documentado, en vez de eliminar el recurso. Ver la capability `legacy-client-compatibility` (change `add-legacy-free-usage-table-shim`).

Al revés también cuenta: un cambio del servidor que **rechaza** algo que un cliente viejo aún envía (por ejemplo, un índice único) se aplica **después** de publicar el cliente que sabe manejar ese rechazo.

Contexto: el 2 de octubre de 2026 se eliminó `daily_summary_free_usage` antes de que la `1.9.0` estuviera pública; el build `1.8.0+18`, que la consultaba en cada sincronización y espera el login sin manejar errores, dejó a un usuario nuevo con el Inbox cargando indefinidamente.

## Arquitectura: Feature-Based Clean Architecture

El proyecto usa Clean Architecture organizada por features, no por capas globales.

### Estructura de carpetas

```
lib/
├── core/                          # infraestructura compartida entre features
│   ├── ai/                        # ArticleSummaryGenerator, MentionEnricher (Edge Functions)
│   ├── auth/                      # AuthClient (Supabase, Google, Apple)
│   ├── config/                    # AppConfig (APP_ENV: dev por defecto, prod solo con dart-define)
│   ├── constants/                 # AppConstants (nombres de boxes Hive, etc.)
│   ├── data/                      # capa de datos COMPARTIDA
│   │   ├── datasources/local/     # interfaces + implementaciones Hive
│   │   ├── models/                # Hive models + .g.dart generados
│   │   └── repositories/          # implementaciones concretas
│   ├── di/                        # injection.dart (único punto de get_it)
│   ├── domain/                    # dominio COMPARTIDO entre features
│   │   ├── entities/              # Article, NewsSource, DailySummary, SummarySourceBlock, ArticleSummary, AiUsageStatus
│   │   └── repositories/          # interfaces (contratos)
│   ├── email_feed/                # EmailFeedGenerator (feeds por email)
│   ├── errors/                    # AppException + AppErrorCode (+ traducción a l10n)
│   ├── feed/                      # FeedParser, FeedSyncTrigger, FeedUrlResolver
│   ├── navigation/                # AppNavigator, ExternalLinkLauncher, RouteExtraResolver
│   ├── network/                   # abstracción HttpClient
│   ├── observability/             # TelemetryClient (Sentry + PostHog), ScreenViewObserver
│   ├── opml/                      # OpmlParser
│   ├── sharing/                   # FileSharer
│   ├── subscription/              # SubscriptionStatusProvider (Superwall)
│   ├── sync/                      # CloudSyncClient, RemoteSourceChecker (Supabase)
│   ├── theme/                     # ReevoAccent (acento óxido, ThemeExtension)
│   ├── utils/                     # IdGenerator, FeedContentChecker, LocalizedDateFormatter, is_local_today…
│   └── widgets/                   # abstracciones de widgets de terceros + SourceIcon, ChamferedBox
├── features/
│   ├── account/                   # exportar datos (JSON/OPML) y borrar cuenta
│   │   └── domain/usecases/       # ExportUserData, ExportFavoritesJson, ExportSourcesOpml, DeleteAccount
│   ├── archive/                   # artículos leídos ("Leídos")
│   │   ├── domain/usecases/       # GetArchive
│   │   └── presentation/          # ArchiveScreen + ArchiveCubit
│   ├── article_summary/           # resumen con IA de un artículo (+ menciones)
│   │   ├── domain/usecases/       # GenerateArticleSummary
│   │   └── presentation/          # ArticleSummaryCubit + widgets
│   ├── auth/                      # login (Google / Apple)
│   │   └── presentation/          # LoginScreen + LoginCubit
│   ├── favorites/                 # favoritos
│   │   ├── domain/usecases/       # GetFavorites
│   │   └── presentation/          # FavoritesScreen + FavoritesCubit
│   ├── inbox/                     # inbox, sincronización y tarjeta del resumen de hoy
│   │   ├── domain/usecases/       # GetInboxArticles, MarkArticleAsRead, GetPendingInboxSummary, DismissDailySummary
│   │   └── presentation/          # InboxScreen + InboxCubit + widgets propios (InboxSummaryCard)
│   ├── maintenance/               # mantenimiento local
│   │   └── domain/usecases/       # MigrateArchivedArticles, ResetLocalArticles
│   ├── reader/                    # experiencia de lectura
│   │   ├── domain/usecases/       # ToggleFavorite
│   │   └── presentation/          # ReaderScreen + ReaderCubit
│   ├── settings/                  # ajustes (cuenta, tema, idioma, suscripción)
│   │   └── presentation/
│   ├── sources/                   # gestión de fuentes
│   │   ├── domain/usecases/       # AddSource, DeleteSource, GetSources, GetSourceArticles, UpdateSourceName, ImportOpml, GenerateEmailFeed
│   │   └── presentation/          # SourcesScreen, AddSourceScreen, ImportOpmlScreen + Cubits
│   ├── summaries/                 # resúmenes diarios (lista y detalle)
│   │   ├── domain/usecases/       # GetDailySummaries, ResolveSummaryArticles, ResolveSummarySources
│   │   └── presentation/          # SummariesScreen, SummaryDetailScreen + widgets (tarjeta por fuente)
│   └── sync/                      # sincronización con Supabase (todos los features)
│       └── domain/usecases/       # SyncUserData, ClearLocalUserData
└── presentation/                  # elementos a nivel de app (no de feature)
    ├── app/                       # App widget + go_router config
    └── theme/                     # AppTheme + ThemeCubit
```

### Reglas de la arquitectura

- Las dependencias apuntan hacia adentro: `presentation → domain ← data`
- Un feature **nunca** importa de otro feature. Si necesita algo compartido, va a `core/`.
- `core/domain/` contiene entidades y repos compartidos (`Article`, `NewsSource`).
- Cada feature tiene sus propios use cases en `domain/usecases/`.
- Cada feature tiene su propia presentación: Bloc/Cubit, screens y widgets en `presentation/`.
- Al agregar un nuevo feature: crear `features/<nombre>/domain/usecases/` y `features/<nombre>/presentation/`.

### Flujo de dependencias por feature

```
features/inbox/presentation/InboxBloc
    → features/inbox/domain/usecases/GetInboxArticles
        → core/domain/repositories/ArticleRepository  (interface)
            ← core/data/repositories/ArticleRepositoryImpl  (implementación)
                → core/data/datasources/local/HiveArticleDatasource
```

## Regla de abstracciones (crítica)

Ninguna librería de infraestructura se importa directamente en `domain/` o `presentation/`. Siempre se usa la interfaz de `core/`:

| Librería | Usar en su lugar |
|----------|-----------------|
| `hive_ce` | `SourceLocalDataSource` / `ArticleLocalDataSource` |
| `http` | `HttpClient` (`core/network/`) |
| `webfeed_plus` | `FeedParser` (`core/feed/`) |
| `webview_flutter` | `ArticleWebView` widget (`core/widgets/`) |
| `flutter_widget_from_html` | `HtmlContentRenderer` widget (`core/widgets/`) |
| `cached_network_image` | `NetworkImageWidget` widget (`core/widgets/`) |
| `go_router` | `AppNavigator` (`core/navigation/`) |
| `uuid` | `IdGenerator` (`core/utils/`) |
| `get_it` | Solo en `core/di/injection.dart`. Nunca llamar `getIt<>()` fuera de ese archivo. |
| `supabase_flutter` | `AuthClient`, `CloudSyncClient`, `RemoteSourceChecker`, `FeedSyncTrigger`, `EmailFeedGenerator`, `ArticleSummaryGenerator`, `MentionEnricher` (`core/auth`, `core/sync`, `core/feed`, `core/email_feed`, `core/ai`) |
| `google_sign_in`, `sign_in_with_apple` | Solo dentro de `SupabaseAuthClient`. |
| `sentry_flutter`, `posthog_flutter` | `TelemetryClient` (`core/observability/`) — errores, eventos de producto y `screen_view`. |
| `superwallkit_flutter` | `SubscriptionStatusProvider` (`core/subscription/`). Excepción: `main.dart` lo configura. |
| `share_plus` | `FileSharer` (`core/sharing/`) |
| `url_launcher` | `ExternalLinkLauncher` (`core/navigation/`) |
| `xml` (OPML) | `OpmlParser` (`core/opml/`); `ExportSourcesOpml` también genera XML en `features/account`. |
| `html` | Solo en `core/feed/` (`html_feed_link_extractor.dart`). |
| `google_fonts` | Solo en `presentation/theme/app_theme.dart`. |

**Excepciones:** `flutter_bloc` / Cubit no se abstrae; es una dependencia estructural. `file_picker` se usa directo en `add_source_screen.dart` (sin abstracción). Hoy algunas screens importan `go_router` para leer `GoRouterState`/navegar con `context.go` (ej. lector, Inbox, Resúmenes): al tocarlas, preferir `AppNavigator`/`RouteExtraResolver` en vez de ampliar ese uso. El cubit de un feature puede depender de un use case de otro solo si ya lo hace hoy (ej. `InboxCubit` usa `GetSources`); para código nuevo, mover lo compartido a `core/`.

## State Management: Bloc / Cubit

- Usar **Cubit** cuando el estado cambia por métodos simples sin flujos de eventos complejos.
- Usar **Bloc** cuando hay múltiples eventos que producen transiciones de estado distintas.
- Los estados **siempre** extienden `Equatable`.
- Nunca mutar estado; siempre emitir un nuevo objeto.
- No poner lógica de negocio en Blocs/Cubits — delegar a use cases.

```dart
// correcto
emit(state.copyWith(isLoading: true));
await _syncSources.execute();
emit(InboxLoaded(articles: result));

// incorrecto
emit(state..articles.add(article)); // mutación
```

## Hive CE

- TypeAdapters generados con `build_runner`. Correr después de cambiar modelos.
- IDs de tipo en uso: `0` `NewsSourceModel`, `1` `ArticleModel`, `2` `DailySummaryModel`, `3` `ArticleSummaryModel`, `4` `AiUsageDailyModel`, `6` `UserPreferencesModel`. El `5` lo usó un modelo ya eliminado (uso gratuito de resúmenes): no reutilizarlo, puede haber cajas viejas en dispositivos. El siguiente libre es `7`.
- Nunca llamar `Hive.box()` fuera de las clases datasource en `core/data/datasources/local/`.
- Las boxes (fuentes, artículos, ajustes, resúmenes, resúmenes de artículo, uso de IA y preferencias de usuario; nombres en `AppConstants`) se abren **una sola vez** en `main.dart` antes de `runApp`.

## Offline-first con push inmediato

La app es offline-first: Hive es la copia de trabajo local de lo que se obtuvo del backend, y la UI siempre lee de ahí (nunca consulta Supabase directo para pintar una pantalla). Supabase es la fuente de la verdad **entre dispositivos**, y `SyncUserData` reconcilia ambos lados.

**Cuando una acción del usuario cambia datos sincronizados** (marcar leído, favorito, descartar la tarjeta de un resumen, etc.), el cambio SHALL aplicarse primero en Hive y luego intentarse **subir de inmediato** a Supabase, sin esperar al próximo sync completo (login, resume, pull-to-refresh). El push inmediato sigue el patrón de `MarkArticleAsRead` / `ToggleFavorite` (ver requirements "Push inmediato…" en `openspec/specs/cloud-sync/spec.md`):

- Best-effort: no bloquea ni retrasa la actualización local ni la UI.
- Cualquier falla (sin red, error del servidor) se ignora sin propagarse a la interfaz; el sync completo la repara después, porque el cambio local queda pendiente de subir.
- Se intenta solo si hay sesión activa.
- Va por `CloudSyncClient.updatePartial` (solo las columnas que cambiaron), no con un upsert de la fila completa.

Al diseñar un feature nuevo con estado que se sincroniza, planear el push inmediato desde el spec (un requirement "Push inmediato de …" con sus escenarios: con conexión, sin conexión, sin sesión, y falla reparada por el sync completo), no dejarlo viajando solo con el sync incremental.

## Internacionalización (i18n)

La app soporta inglés, español (neutro) y francés, vía el mecanismo oficial de Flutter — `flutter_localizations` + archivos `.arb` + `flutter gen-l10n` (no `easy_localization` ni ningún otro paquete de terceros).

**Ningún texto nuevo visible al usuario se agrega sin sus 3 traducciones.** Cualquier feature o fix que introduzca un mensaje de texto (estado de error, copy de UI, notificación, etc.) SIEMPRE agrega la clave correspondiente en los 3 `.arb` (inglés, español, francés) en el mismo change — nunca solo en uno y "después se traduce". Aplica también a mensajes que se arman por código (ej. un nuevo `AppErrorCode`), no solo a texto estático de widgets.

- Claves en `lib/l10n/app_en.arb` (template, siempre completo), `app_es.arb` (contenido real en español neutro con tuteo) y `app_fr.arb` (hoy con placeholders en inglés — el contenido francés real está pendiente).
- Después de tocar cualquier `.arb`, correr `flutter gen-l10n` para regenerar `lib/l10n/app_localizations.dart`.
- En `presentation/`, obtener las traducciones con `AppLocalizations.of(context)` (sin `!`, `nullable-getter: false` en `l10n.yaml`) e importar `package:newsreader/l10n/app_localizations.dart`.
- Convención de nombres de clave: `<feature><Descripción>` (ej. `sourcesEmptyTitle`), con un grupo `common*` para texto genuinamente compartido entre features (`commonCancel`, `commonDelete`, etc.) — no dupliques la traducción de la misma palabra con dos claves distintas.
- **Español neutro, sin voseo**: nunca "tocá", "agregá", "suscribí" — sí "toca", "agrega", "suscribe". El test `test/unit/l10n/neutral_spanish_test.dart` falla si aparece una conjugación de voseo conocida en `app_es.arb`; agrega ahí cualquier forma nueva que encuentres. Esta regla no es exclusiva de `app_es.arb`: aplica a **cualquier** texto en español del proyecto, incluidos los prompts en español embebidos en las Edge Functions que le hablan a Gemini (ej. `supabase/functions/summarize-article/index.ts`, `summarize-articles/index.ts`) — ese texto no pasa por `neutral_spanish_test.dart`, así que hay que revisarlo a mano antes de darlo por bueno.
- Fechas: nunca formatear a mano (`'${date.day}/${date.month}'` ni arrays de nombres de mes). Usar `LocalizedDateFormatter` (`core/utils/localized_date_formatter.dart`), que ya resuelve idioma/orden/nombres de mes vía `DateFormat` de `intl`.
- `AppException` y sus subclases (`core/errors/app_exception.dart`) ya no cargan texto humano: se identifican por `AppErrorCode`, que se traduce en la capa de presentación (ver `add-localized-error-codes`, archivado). No reintroduzcas un `String message` para mostrarle algo al usuario — agregá un `AppErrorCode` nuevo en su lugar.

## Convenciones de código

- `const` en todos los constructores y widgets donde sea posible.
- Nombres de archivos: `snake_case.dart`.
- Una clase/widget por archivo.
- Los widgets no contienen lógica de negocio; solo construyen UI y despachan eventos.
- Inyectar dependencias por constructor; nunca instanciar servicios dentro de un widget.
- Íconos de fuente: siempre `SourceIcon` (`core/widgets/`), que ya resuelve el fallback a la inicial en óxido; avatares redondos apilados son la excepción y repiten ese fallback.
- Color de marca: el óxido vive en `ReevoAccent` (`core/theme/`), no en `ColorScheme`. Para tonos que no existen en el tema (ej. los beiges de las tarjetas de resumen) usar constantes locales con variante clara y oscura, no `surfaceContainerHighest`/`outlineVariant`, que en `AppTheme` son hairlines translúcidos que se leen grises.
- `dart format`: formatear solo los archivos que tocaste. Correrlo sobre carpetas enteras reformatea archivos ajenos; revisar `git diff --stat` después.

## Testing

- Mocks con `mocktail` (no `mockito`).
- Tests de Bloc/Cubit con `bloc_test`.
- Los widget tests envuelven el widget bajo prueba en `MultiBlocProvider` con mocks.
- Un test no debe depender del estado de otro test (sin estado compartido entre tests).
- Las pruebas manuales en simulador/dispositivo (correr la app, navegar, tomar screenshots) las hace el usuario. No lancees `flutter run` en un simulador ni automatices taps para verificar cambios de UI, salvo que el usuario lo pida explícitamente.

## Compatibilidad con iPad

Reevo soporta iPad con un layout adaptativo (`NavigationRail` permanente + master-detail de 2 paneles en anchos ≥840dp, breakpoint "expanded" de Material 3; por debajo se mantiene el `NavigationDrawer` modal y el push de pantalla completa) — ver capabilities `adaptive-navigation-rail` y `adaptive-master-detail`, introducidas por el change archivado `optimize-ipad-ux`.

**Todo change que agregue o modifique una pantalla debe seguir siendo compatible con este layout, sin excepción:**

- Ninguna screen de detalle nueva puede asumir que es la pantalla completa: debe poder embeberse dentro del panel derecho del master-detail (sin `Scaffold`/`AppBar` que dupliquen chrome ya provisto por el panel) y también funcionar con push de pantalla completa por debajo del breakpoint.
- Toda screen de lista nueva que participe de una tab existente (o una tab nueva) debe exponer/consumir el estado de "ítem seleccionado" igual que Inbox/Favoritos/Archivo/Fuentes/Resúmenes, preservando la selección al cruzar el breakpoint (rotación o resize) sin perder scroll/progreso.
- El ancho máximo de texto (~680pt, centrado) del lector aplica en cualquier ancho de pantalla; no reintroducir HTML/texto sin límite de ancho en una pantalla nueva de contenido largo.
- Antes de dar un cambio de UI por terminado, confirmar (razonando sobre el ancho ≥840dp, no solo mobile) que no rompe el rail, el split view, ni la persistencia de selección — las pruebas manuales en iPad las corre el usuario (ver regla de simulador), pero el razonamiento sobre el layout adaptativo es responsabilidad de Claude al implementar.

## Rutas de navegación

```
/login                          Login (redirect si no hay sesión)
/                               Inbox
/summary/:id                    Detalle del resumen de hoy (dentro del Inbox)
/article/:id                    Lector (desde Inbox) — sub-ruta /web: artículo web
/archive                        Archivo ("Leídos")
/archive/article/:id            Lector (desde Archivo)
/favorites                      Favoritos
/favorites/article/:id          Lector (desde Favoritos)
/sources                        Fuentes
/sources/:id                    Artículos de una fuente
/sources/:id/article/:articleId Lector (desde una fuente)
/sources/add                    Agregar fuente
/sources/import-opml            Importar OPML (extra: contenido XML)
/summaries                      Lista de resúmenes diarios
/summaries/:date                Detalle de un resumen
/summaries/:date/article/:articleId  Lector (desde un resumen)
/settings                       Ajustes
```

Inbox, Favoritos, Archivo, Fuentes y Resúmenes son `StatefulShellBranch` con `ShellRoute` interno para el master-detail; el lector se reusa en las 5 vía `_articleRoute` (`router.dart`). Verificar siempre las rutas reales en `lib/presentation/app/router.dart` antes de documentar o depender de una.

## Reglas de negocio clave

- Artículo se marca como leído automáticamente al abrirlo.
- No hay archivado ni borrado automático por antigüedad: los artículos no leídos permanecen en el inbox indefinidamente, y los leídos permanecen en "Leídos" indefinidamente (ver `openspec/specs/article-lifecycle/spec.md`).
- Favoritos nunca se eliminan automáticamente.
- Contenido truncado: `contentHtml == null || contentHtml.length < 500`.
- El parseo de RSS/Atom no vive en el cliente: lo hace la Edge Function `sync-feeds` (`supabase/functions/sync-feeds/`), disparada por `FeedSyncTrigger`/`SupabaseFeedSyncTrigger` (`core/feed/`) desde el cliente. El cliente solo pide el fetch y espera la respuesta; no existe un `SyncSources` del lado del cliente. Timeout por feed del lado del servidor: 10 segundos (`FEED_FETCH_TIMEOUT_MS`). Un fallo no interrumpe las demás fuentes.
- Resumen diario: lo genera el servidor (`generate-daily-summaries`), como máximo uno por fecha local por usuario y sin regeneración. Es elegible quien tiene suscripción activa (cualquier día) o, sin suscripción, solo los lunes. El cliente solo lo recibe por `SyncUserData` y lo muestra: tarjeta del Inbox (resumen de hoy sin `dismissed_at`; abrirlo lo descarta), lista y detalle en la tab Resúmenes. Cada resumen guarda su agrupación por fuente (`sourceBlocks`); los anteriores a esa funcionalidad no la tienen y se muestran sin tarjetas ni íconos. Ver `openspec/specs/daily-summaries/spec.md` y `inbox-daily-summary-card`.
- Resumen con IA de un artículo (`article_summary`) y menciones: pasan por Edge Functions (Gemini, Google Books, iTunes), con presupuesto diario por usuario (`AiUsageRepository`, ver `ai-usage-budget`) y acceso según suscripción (`SubscriptionStatusProvider`, ver `subscription-entitlements`).
- Preferencias de usuario (idioma, offset horario) se sincronizan (`user-preferences`): el servidor las usa para generar el resumen en el idioma y el día local correctos.
- La sincronización con la nube (subir/bajar fuentes, artículos y resúmenes) vive en `features/sync/domain/usecases/SyncUserData`, independiente del fetch de feeds — ver capability `openspec/specs/cloud-sync/spec.md`.

## Flujo de trabajo

Todos los features se implementan por medio de OpenSpec (`/opsx:propose` → `/opsx:apply` → `/opsx:archive`), sin excepción, aunque el scope parezca chico.

**`main` está protegida: nunca se pushea ni se mergea código directo ahí.** El flujo correcto es:

1. Crear una rama nueva para el change (ej. `add-nombre-del-change`).
2. Implementar en esa rama (`/opsx:apply`), corriendo `flutter analyze` y `flutter test` localmente antes de subir.
3. Una vez que las pruebas locales pasan, pushear la rama y abrir un PR contra `main`.
4. Esperar a que el check de CI (`analyze-and-test` en GitHub Actions) pase en el PR — `main` tiene branch protection que exige ese check en verde antes de habilitar el merge.
5. Apenas ese check esté en verde, mergear el PR sin pedir confirmación adicional — el usuario ya autorizó esto de forma permanente (2026-09-08). Esta autorización cubre solo el merge en sí; push, apertura de PR, y cualquier acción fuera de este flujo siguen requiriendo confirmación como de costumbre.
6. Una vez verificado el flujo completo (todas las tareas de `tasks.md` confirmadas, no solo implementadas), archivar el change de OpenSpec (`/opsx:archive`) — el archive también se sube por PR, no directo a `main`.
7. Tras mergear el PR (de implementación, de archive, o cualquier PR suelto), volver a `main`, actualizarla, y borrar la rama ya mergeada (local y remota) — no dejar ramas viejas acumulándose. Un feature no queda "terminado" hasta este paso.

**Cerrar tareas y archivar van en el mismo PR final**, no en dos PRs separados — marcar `tasks.md` como completo y mover el change a `archive/` es un solo commit/PR. Solo se separan si aparece un bug real a mitad de camino que necesita su propio ciclo de verificación (rama + PR + CI) antes de poder cerrar la tarea correspondiente.

**Archivar un change:** `openspec archive <name> --yes` aplica el delta al spec principal y mueve el change. Si el delta *reemplaza* escenarios de un requirement (los quita y agrega otros), el CLI se niega ("scenario(s) not present in the modified block"): en ese caso fusionar el requirement a mano en `openspec/specs/<capability>/spec.md`, correr `openspec validate --specs` y archivar con `--skip-specs`. `/opsx:apply`/`/opsx:propose` crean la rama y los artefactos; el change se cierra y archiva en el mismo PR final.

**Pruebas en dispositivo:** las builds de prueba salen por TestFlight (Codemagic, trigger manual, `APP_ENV=prod`); un problema encontrado ahí se corrige en un change aparte, no reabriendo el archivado. CI de GitHub (`ci.yml`) corre `flutter analyze` + `flutter test` en cada PR.

Nunca usar `git push` directo a `main` ni `--no-verify`/bypass de branch protection salvo que el usuario lo pida explícitamente.

## Commits

Seguir [Conventional Commits](https://www.conventionalcommits.org/): `<tipo>: <descripción>` en minúscula, sin punto final, **en inglés** (el asunto y el cuerpo; la conversación con el usuario sigue en español).

Tipos usados en este proyecto: `feat`, `fix`, `chore`. (`docs`, `refactor`, `test`, `perf` quedan disponibles si aplica, pero no se han usado todavía.)

- Un commit por cambio lógico independiente — si un change de OpenSpec tocó varias áreas no relacionadas, separar en varios commits en vez de uno solo mezclado.
- El cuerpo (opcional, después de una línea en blanco) explica el *por qué*, no el *qué* — el diff ya muestra el qué.

```
feat: show the feed's featured image in the article list
fix: cascade a source deletion to its articles in Supabase
chore: bump version to 1.6.0+7
```

## Documentos de referencia

- `PRD.md` — requisitos del producto
- `USER_STORIES.md` — historias de usuario con criterios de aceptación
- `SOLUTION_SPEC.md` — decisiones técnicas detalladas
