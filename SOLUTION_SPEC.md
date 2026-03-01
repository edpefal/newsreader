# Solution Spec: Newsletter Hub (MVP)

> Documento técnico de referencia para la implementación. Basado en el PRD v1 y las 18 historias de usuario definidas.

---

## 1. Stack Tecnológico

| Decisión | Elección | Justificación |
|----------|----------|---------------|
| Framework | Flutter (iOS + Android) | Único codebase para ambas plataformas |
| State Management | Bloc / Cubit | Estructura explícita y predecible; Cubit para estados simples, Bloc para flujos con eventos |
| Base de datos local | Hive CE | NoSQL embebido, rápido, sin SQL boilerplate, TypeAdapters en Dart |
| Arquitectura | Clean Architecture | Domain / Data / Presentation desacopladas y testeables |
| Navegación | go_router | Router oficial Flutter, URL-based, compatible con deep links |
| Inyección de dependencias | get_it | Service locator simple, estándar de facto con Clean Arch + Bloc |
| RSS Parser | webfeed | Soporte nativo RSS 2.0 y Atom con API simple |
| WebView | webview_flutter | Suficiente para cargar URLs de artículos de pago |
| HTML Renderer | flutter_widget_from_html | Renderiza el `<content>` del RSS como widgets Flutter |
| HTTP | http | Sin over-engineering para requests de feeds |
| Imágenes | cached_network_image | Cache automático de íconos de fuentes |
| Tema | Material 3 + toggle manual | Dark / Light mode independiente del sistema |
| Testing | Unit + Widget tests críticos | Use cases, repositorios y pantallas principales |

---

## 2. Principio de Abstracciones

Ninguna librería de infraestructura se usa directamente desde la capa de dominio o presentación. Cada librería de terceros queda detrás de una interfaz definida en `core/` o en la capa `data/`, de modo que puede ser reemplazada sin tocar use cases, Blocs ni pantallas.

**Excepción explícita:** `flutter_bloc` / Cubit es una dependencia esencial y estructural; no se abstrae.

| Librería | Interfaz / Abstracción | Implementación concreta |
|----------|----------------------|------------------------|
| **Hive CE** | `SourceLocalDataSource` / `ArticleLocalDataSource` (interfaces en `data/datasources/local/`) | `HiveSourceDatasource` / `HiveArticleDatasource` |
| **http** | `HttpClient` (interfaz en `core/network/`) | `HttpPackageClient` |
| **webfeed** | `FeedParser` (interfaz en `core/feed/`) | `WebfeedFeedParser` |
| **webview_flutter** | `ArticleWebView` (widget abstracto en `core/widgets/`) | `WebViewFlutterArticleWebView` |
| **flutter_widget_from_html** | `HtmlContentRenderer` (widget abstracto en `core/widgets/`) | `FwhHtmlContentRenderer` |
| **cached_network_image** | `NetworkImageWidget` (widget abstracto en `core/widgets/`) | `CachedNetworkImageWidget` |
| **go_router** | `AppNavigator` (interfaz en `core/navigation/`) | `GoRouterAppNavigator` |
| **uuid** | `IdGenerator` (interfaz en `core/utils/`) | `UuidIdGenerator` |
| **get_it** | — | Service locator; su uso queda confinado a `core/di/injection.dart`. Nunca se llama `getIt<>()` fuera de ese archivo. |

### Estructura adicional en `core/`

```
core/
├── di/
│   └── injection.dart          # único lugar donde se llama getIt
├── network/
│   ├── http_client.dart        # interface HttpClient
│   └── http_package_client.dart
├── feed/
│   ├── feed_parser.dart        # interface FeedParser
│   └── webfeed_feed_parser.dart
├── navigation/
│   ├── app_navigator.dart      # interface AppNavigator
│   └── go_router_navigator.dart
├── widgets/
│   ├── html_content_renderer.dart     # abstract widget
│   ├── fwh_html_content_renderer.dart
│   ├── article_web_view.dart          # abstract widget
│   ├── webview_flutter_article_web_view.dart
│   ├── network_image_widget.dart      # abstract widget
│   └── cached_network_image_widget.dart
└── utils/
    ├── id_generator.dart       # interface IdGenerator
    └── uuid_id_generator.dart
```

---

## 3. Arquitectura

### 3.1 Estructura de Carpetas

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart        # ARTICLE_TRUNCATED_THRESHOLD, CLEANUP_DAYS, etc.
│   ├── errors/
│   │   └── failures.dart             # NetworkFailure, ParseFailure, NotFoundFailure
│   └── utils/
│       ├── feed_validator.dart        # Detecta contenido truncado
│       └── date_utils.dart
│
├── domain/
│   ├── entities/
│   │   ├── news_source.dart
│   │   └── article.dart
│   ├── repositories/
│   │   ├── source_repository.dart    # interface
│   │   └── article_repository.dart   # interface
│   └── usecases/
│       ├── source/
│       │   ├── add_source.dart
│       │   ├── delete_source.dart
│       │   ├── update_source_name.dart
│       │   └── get_sources.dart
│       ├── article/
│       │   ├── sync_sources.dart
│       │   ├── get_inbox_articles.dart
│       │   ├── mark_article_as_read.dart
│       │   ├── toggle_favorite.dart
│       │   ├── get_favorites.dart
│       │   └── get_archive.dart
│       └── maintenance/
│           └── run_maintenance.dart
│
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── hive_source_datasource.dart
│   │   │   └── hive_article_datasource.dart
│   │   └── remote/
│   │       └── feed_remote_datasource.dart   # HTTP + webfeed
│   ├── models/
│   │   ├── news_source_model.dart    # HiveObject + TypeAdapter
│   │   └── article_model.dart        # HiveObject + TypeAdapter
│   └── repositories/
│       ├── source_repository_impl.dart
│       └── article_repository_impl.dart
│
├── presentation/
│   ├── app/
│   │   ├── app.dart                  # MaterialApp + go_router + BlocProviders
│   │   └── router.dart               # GoRouter config
│   ├── theme/
│   │   ├── app_theme.dart            # Light + Dark ThemeData
│   │   └── theme_cubit.dart          # Persiste preferencia en Hive
│   ├── screens/
│   │   ├── inbox/
│   │   │   ├── inbox_screen.dart
│   │   │   └── inbox_bloc.dart
│   │   ├── reader/
│   │   │   ├── reader_screen.dart
│   │   │   └── reader_cubit.dart
│   │   ├── favorites/
│   │   │   ├── favorites_screen.dart
│   │   │   └── favorites_cubit.dart
│   │   ├── archive/
│   │   │   ├── archive_screen.dart
│   │   │   └── archive_cubit.dart
│   │   └── sources/
│   │       ├── sources_screen.dart
│   │       ├── sources_cubit.dart
│   │       └── add_source/
│   │           ├── add_source_screen.dart
│   │           └── add_source_cubit.dart
│   └── widgets/
│       ├── article_list_item.dart
│       ├── source_list_item.dart
│       ├── empty_state.dart
│       └── error_banner.dart
│
└── main.dart
```

---

## 4. Modelo de Datos

### 3.1 Entidades de Dominio

```dart
// domain/entities/news_source.dart
class NewsSource {
  final String id;           // UUID
  final String name;         // Editable por el usuario
  final String feedUrl;      // URL del feed RSS/Atom
  final String? author;
  final String? iconUrl;
  final DateTime addedAt;
  final DateTime? lastSyncedAt;
  final bool hasError;       // true si el último sync falló
}

// domain/entities/article.dart
class Article {
  final String id;           // UUID generado localmente
  final String sourceId;     // FK a NewsSource
  final String sourceName;   // Desnormalizado para evitar joins
  final String? sourceIconUrl;
  final String title;
  final String? author;
  final DateTime publishedAt;
  final String? contentHtml; // Campo <content> del RSS
  final String? excerpt;     // Campo <description> del RSS (fallback)
  final String articleUrl;   // URL original del artículo
  final bool isRead;
  final bool isFavorite;
  final bool isArchived;
  final DateTime? readAt;
  final DateTime? savedAsFavoriteAt;
}
```

### 3.2 Modelos Hive (capa Data)

Los modelos Hive extienden las entidades de dominio con anotaciones `@HiveType` / `@HiveField`.

```dart
// Hive type IDs reservados
// 0 → NewsSourceModel
// 1 → ArticleModel
```

**Boxes de Hive:**

| Box | Tipo | Clave | Propósito |
|-----|------|-------|-----------|
| `sources` | `NewsSourceModel` | `source.id` | Fuentes activas |
| `articles` | `ArticleModel` | `article.id` | Todos los artículos |
| `settings` | `dynamic` | string keys | Preferencias (tema, reader mode) |

**Settings keys:**

| Key | Tipo | Default |
|-----|------|---------|
| `theme_mode` | `String` (`light`/`dark`) | `light` |
| `reader_mode_enabled` | `bool` | `false` |

---

## 5. Navegación (go_router)

```
/                           → InboxScreen          (tab 0)
  /archive                  → ArchiveScreen        (desde badge en Inbox)
    /archive/:articleId     → ReaderScreen
  /article/:articleId       → ReaderScreen
/favorites                  → FavoritesScreen      (tab 1)
  /favorites/:articleId     → ReaderScreen
/sources                    → SourcesScreen        (tab 2)
  /sources/add              → AddSourceScreen
```

**Bottom Navigation:** 3 tabs — Inbox · Favoritos · Fuentes
**Archivo:** No ocupa tab. Aparece como fila/banner al final del Inbox solo cuando hay artículos archivados. Navega a `/archive`.

---

## 6. Casos de Uso

### 5.1 AddSource

```
Input: feedUrl (String)
1. Validar formato de URL
2. HTTP GET feedUrl (timeout: 10s)
   → Error: NetworkFailure si no hay conexión
   → Error: TimeoutFailure si supera 10s
3. Parsear respuesta con webfeed
   → Error: ParseFailure si no es RSS/Atom válido
4. Verificar que feedUrl no exista ya en Hive (deduplicación)
   → Error: DuplicateSourceFailure
5. Crear NewsSource con metadatos extraídos del feed
6. Guardar en Hive box 'sources'
7. Hacer primer fetch de artículos para esa fuente (ver SyncSources)
Output: NewsSource creada
```

### 5.2 SyncSources

```
Input: lista de NewsSource (o todas las activas)
Para cada fuente en paralelo (Future.wait):
  1. HTTP GET source.feedUrl (timeout: 10s)
  2. Parsear feed con webfeed
  3. Para cada item del feed:
     a. Si article.url ya existe en Hive → skip
     b. Crear ArticleModel con isRead=false, isFavorite=false, isArchived=false
     c. Guardar en Hive box 'articles'
  4. Actualizar source.lastSyncedAt
  5. Si hubo error → marcar source.hasError=true, continuar con las demás
Output: SyncResult { synced: int, errors: List<String> }
```

### 5.3 RunMaintenance

```
Input: ninguno (se ejecuta al iniciar la app)
Ejecutar en background (Isolate o compute):
1. Obtener todos los artículos
2. Para cada artículo donde isRead=true AND isFavorite=false:
   - Si publishedAt < (now - 30 días) → eliminar de Hive
3. Para cada artículo donde isRead=false AND isArchived=false:
   - Si publishedAt < (now - 30 días) → marcar isArchived=true
Output: MaintenanceResult { deleted: int, archived: int }
```

### 5.4 DetectTruncatedContent

```
Input: contentHtml (String?)
Lógica:
- Si contentHtml es null o vacío → truncado
- Si contentHtml.length < 500 caracteres → truncado
Output: bool isTruncated
```

---

## 7. State Management (Bloc/Cubit)

### InboxBloc

```
Events:
  InboxLoaded          → carga artículos no leídos de Hive
  InboxSyncRequested   → pull-to-refresh, llama SyncSources
  InboxArticleOpened   → llama MarkArticleAsRead, recarga lista

States:
  InboxInitial
  InboxLoading
  InboxLoaded(articles: List<Article>)
  InboxSyncing(articles: List<Article>)       // muestra lista + spinner
  InboxSyncError(message: String, articles: List<Article>)  // lista sigue visible
  InboxEmpty                                  // sin artículos no leídos
```

### AddSourceCubit

```
States:
  AddSourceInitial
  AddSourceValidating   // spinner mientras valida URL
  AddSourceSuccess(source: NewsSource)
  AddSourceError(message: String)
```

### SourcesCubit

```
States:
  SourcesLoaded(sources: List<NewsSource>)
  // operaciones (delete, rename) emiten SourcesLoaded actualizado
```

### ReaderCubit

```
State:
  ReaderState {
    article: Article,
    isReaderMode: bool,
    isTruncated: bool,    // calculado por DetectTruncatedContent
  }

Methods:
  toggleReaderMode()    → persiste preferencia en Hive settings
  toggleFavorite()      → llama ToggleFavorite use case
```

### ThemeCubit

```
States: ThemeLight | ThemeDark
toggleTheme() → persiste en Hive settings['theme_mode']
```

---

## 8. Dependencias (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Navegación
  go_router: ^14.0.0

  # Base de datos
  hive_ce: ^2.9.0
  hive_ce_flutter: ^2.2.0

  # Networking & Feeds
  http: ^1.2.0
  webfeed_plus: ^1.0.0        # fork activo de webfeed

  # UI
  cached_network_image: ^3.3.1
  flutter_widget_from_html: ^0.15.0   # renderiza HTML del feed
  webview_flutter: ^4.7.0

  # Inyección de dependencias
  get_it: ^7.7.0

  # Utils
  uuid: ^4.4.0                # generación de IDs
  intl: ^0.19.0               # formateo de fechas

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mocktail: ^1.0.3
  hive_ce_generator: ^1.8.0
  build_runner: ^2.4.0
```

---

## 9. Pantallas y Responsabilidades

### InboxScreen
- Escucha `InboxBloc`
- `RefreshIndicator` wrapping la lista (pull-to-refresh → `InboxSyncRequested`)
- `ArticleListItem` por cada artículo
- Empty state con CTA si `InboxEmpty`
- Banner de error no bloqueante si `InboxSyncError`
- Al final de la lista: fila "N artículos archivados ›" visible solo si hay artículos archivados; navega a `/archive`

### ReaderScreen
- Recibe `articleId` por parámetro de ruta
- `ReaderCubit` carga el artículo desde Hive (no hace HTTP)
- `flutter_widget_from_html` para Vista Original
- Si `isTruncated == true`: muestra excerpt + botón "Leer en el sitio original"
- `webview_flutter` se abre en pantalla completa al pulsar ese botón
- Toggle Reader Mode en AppBar (ícono)
- Oculta AppBar y BottomNav al hacer scroll down (`ScrollController`)

### AddSourceScreen
- TextField para URL
- Botón "Agregar" → dispara `AddSourceCubit.addSource(url)`
- Estado `AddSourceValidating` muestra `CircularProgressIndicator` en el botón
- `AddSourceError` muestra snackbar con el mensaje de error

### SourcesScreen
- Lista de fuentes con ícono (favicon o círculo con inicial), nombre y estado de error
- Swipe-to-delete con confirmación
- Tap en nombre → inline edit o bottom sheet para renombrar
- FAB "+ Agregar newsletter" → navega a `/sources/add`

---

## 10. Manejo de Errores

| Error | Capa que lo captura | UX |
|-------|--------------------|----|
| Sin internet (sync) | InboxBloc | Banner no bloqueante, lista sigue visible |
| Timeout de feed (sync) | SyncSources use case | Marca `source.hasError=true`, muestra warning por fuente |
| URL inválida (add source) | AddSourceCubit | Snackbar con mensaje específico |
| Feed duplicado | AddSourceCubit | Snackbar "Ya estás suscrito a esta fuente" |
| Contenido truncado | ReaderCubit | Botón fallback a WebView |

---

## 11. Testing

### Unit Tests (prioritarios)

| Archivo de test | Qué cubre |
|-----------------|-----------|
| `add_source_test.dart` | Validación URL, deduplicación, ParseFailure |
| `sync_sources_test.dart` | Artículos nuevos vs existentes, error por fuente |
| `run_maintenance_test.dart` | Limpieza de leídos, archivo de no leídos, respeta favoritos |
| `detect_truncated_content_test.dart` | Casos: null, vacío, <500 chars, contenido completo |
| `article_repository_impl_test.dart` | CRUD con Hive mockeado |

### Widget Tests (críticos)

| Archivo de test | Qué cubre |
|-----------------|-----------|
| `inbox_screen_test.dart` | Empty state, lista con artículos, pull-to-refresh, error banner |
| `reader_screen_test.dart` | Vista normal, toggle reader mode, botón fallback WebView |
| `add_source_screen_test.dart` | Loading state, success, error por URL inválida |

---

## 12. Inicialización de la App

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NewsSourceModelAdapter());
  Hive.registerAdapter(ArticleModelAdapter());
  await Hive.openBox<NewsSourceModel>('sources');
  await Hive.openBox<ArticleModel>('articles');
  await Hive.openBox('settings');

  // 2. Configurar inyección de dependencias con get_it
  await setupDependencies();   // registra repos, use cases, cubits

  // 3. Ejecutar mantenimiento silencioso
  await getIt<RunMaintenance>().execute();

  runApp(const App());
}
```

---

## 13. Resumen de Decisiones

| Punto | Decisión |
|-------|----------|
| Umbral de contenido truncado | `contentHtml == null \|\| contentHtml.length < 500` |
| Inyección de dependencias | `get_it` con función `setupDependencies()` en `core/di/` |
| Ícono fallback de fuente | Círculo con inicial del nombre (sin assets externos) |
| Sección Archivo en navegación | Badge al final del Inbox, navega a `/archive` |
