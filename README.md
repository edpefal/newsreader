# Newsletter Hub

Una app Flutter para centralizar newsletters fuera del correo electrónico. Agrega feeds RSS/Atom, lee artículos en un lector limpio, guarda favoritos y archiva contenido automáticamente.

## Características

- **Inbox** — artículos no leídos ordenados por fecha, con badge de conteo en la barra de navegación
- **Sincronización** — pull-to-refresh con feedback de errores de red o fuentes fallidas
- **Lector** — vista de contenido HTML, modo reader (texto plano) y acceso vía WebView
- **Favoritos** — marca/desmarca artículos con la estrella; sección dedicada con recarga automática al cambiar de tab
- **Archivados** — artículos archivados automáticamente por el proceso de mantenimiento
- **Gestión de fuentes** — agregar por URL (auto-detección de metadatos), editar nombre, eliminar
- **Limpieza automática** — artículos leídos >30 días se eliminan; no leídos >30 días se archivan (al inicio de la app)
- **Tema** — soporte light/dark con persistencia en Hive

## Stack

| Capa | Tecnología |
|------|-----------|
| State management | `flutter_bloc` / Cubit |
| Navegación | `go_router` (StatefulShellRoute + tabs) |
| Base de datos local | `hive_ce` |
| Feeds | `webfeed_plus` (RSS/Atom) |
| Red | `http` |
| Renderizado HTML | `flutter_widget_from_html` |
| WebView | `webview_flutter` |
| DI | `get_it` |
| Imágenes en caché | `cached_network_image` |

## Arquitectura

Clean Architecture por features, con separación estricta de capas:

```
lib/
├── core/
│   ├── constants/         # AppConstants (cleanupDays, box names, etc.)
│   ├── data/
│   │   ├── datasources/local/   # HiveArticleDatasource, HiveSourceDatasource
│   │   ├── models/              # ArticleModel, NewsSourceModel (HiveObjects)
│   │   └── repositories/        # ArticleRepositoryImpl, SourceRepositoryImpl
│   ├── di/                # GetIt setup (injection.dart)
│   ├── domain/
│   │   ├── entities/      # Article, NewsSource
│   │   └── repositories/  # Interfaces: ArticleRepository, SourceRepository
│   ├── errors/            # NetworkException, ParseException, etc.
│   ├── feed/              # FeedParser abstracción + WebfeedFeedParser
│   ├── navigation/        # AppNavigator + GoRouterNavigator
│   ├── network/           # HttpClient + HttpPackageClient
│   ├── utils/             # IdGenerator + UuidIdGenerator
│   └── widgets/           # SourceIcon, WebviewFlutterArticleWebView
├── features/
│   ├── archive/           # GetArchive · ArchiveCubit · ArchiveScreen
│   ├── favorites/         # GetFavorites · FavoritesCubit · FavoritesScreen
│   ├── inbox/             # GetInboxArticles · SyncSources · MarkArticleAsRead
│   │                      # InboxCubit · InboxScreen · ArticleInboxTile
│   ├── maintenance/       # RunMaintenance (delete leídos, archive no leídos)
│   ├── reader/            # ToggleFavorite · ReaderScreen
│   └── sources/           # AddSource · DeleteSource · UpdateSourceName
│                          # GetSources · SourcesCubit · SourcesScreen
└── presentation/
    ├── app/               # App widget, GoRouter (appRouter)
    └── theme/             # ThemeCubit, AppTheme (Material 3)
```

## Tests

92 tests (14 archivos) — unitarios de cubits y casos de uso, y de widgets para todas las pantallas:

```
test/
├── unit/features/
│   ├── archive/presentation/cubit/
│   ├── favorites/presentation/cubit/
│   ├── inbox/presentation/cubit/
│   ├── maintenance/domain/usecases/
│   └── sources/presentation/cubit/
└── widget/features/
    ├── archive/
    ├── favorites/
    ├── inbox/
    ├── reader/
    └── sources/
```

## Inicio rápido

```bash
flutter pub get
flutter run
```

> Requiere Flutter 3.x con Dart SDK ^3.8.1.
