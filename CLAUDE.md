# Newsletter Hub — Instrucciones para Claude

## Comandos esenciales

```bash
flutter pub get                          # instalar dependencias
flutter run                              # correr la app
flutter test                             # correr todos los tests
flutter test test/unit/                  # solo unit tests
flutter test test/widget/                # solo widget tests
flutter analyze                          # lint (correr antes de considerar algo listo)
dart run build_runner build              # regenerar TypeAdapters de Hive CE
dart run build_runner build --delete-conflicting-outputs  # si hay conflictos
```

Correr `flutter analyze` después de cualquier cambio de código. No dejar warnings sin resolver.

## Arquitectura: Feature-Based Clean Architecture

El proyecto usa Clean Architecture organizada por features, no por capas globales.

### Estructura de carpetas

```
lib/
├── core/                          # infraestructura compartida entre features
│   ├── constants/
│   ├── data/                      # capa de datos COMPARTIDA
│   │   ├── datasources/local/     # interfaces + implementaciones Hive
│   │   ├── models/                # Hive models + .g.dart generados
│   │   └── repositories/         # implementaciones concretas
│   ├── di/                        # injection.dart (único punto de get_it)
│   ├── domain/                    # dominio COMPARTIDO entre features
│   │   ├── entities/              # Article, NewsSource
│   │   └── repositories/         # interfaces (contratos)
│   ├── errors/
│   ├── feed/                      # abstracción FeedParser
│   ├── navigation/                # abstracción AppNavigator
│   ├── network/                   # abstracción HttpClient
│   ├── utils/                     # IdGenerator, FeedContentChecker
│   └── widgets/                   # abstracciones de widgets de terceros
├── features/
│   ├── sources/                   # Épica 1: gestión de fuentes
│   │   ├── domain/usecases/       # AddSource, DeleteSource, GetSources, UpdateSourceName
│   │   └── presentation/          # SourcesScreen + Bloc/Cubit + widgets propios
│   ├── inbox/                     # Épica 2: inbox y sincronización
│   │   ├── domain/usecases/       # SyncSources, GetInboxArticles, MarkArticleAsRead
│   │   └── presentation/          # InboxScreen + InboxBloc + widgets propios
│   ├── reader/                    # Épica 3: experiencia de lectura
│   │   ├── domain/usecases/       # ToggleFavorite
│   │   └── presentation/          # ReaderScreen + ReaderCubit
│   ├── favorites/                 # Épica 4a: favoritos
│   │   ├── domain/usecases/       # GetFavorites
│   │   └── presentation/          # FavoritesScreen + FavoritesCubit
│   ├── archive/                   # Épica 4b: archivo
│   │   ├── domain/usecases/       # GetArchive
│   │   └── presentation/          # ArchiveScreen + ArchiveCubit
│   └── maintenance/               # Épica 5: limpieza automática
│       └── domain/usecases/       # RunMaintenance
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

**Excepción:** `flutter_bloc` / Cubit no se abstrae; es una dependencia estructural.

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
- IDs de tipo reservados: `0` = `NewsSourceModel`, `1` = `ArticleModel`.
- Nunca llamar `Hive.box()` fuera de las clases datasource en `core/data/datasources/local/`.
- Las boxes se abren **una sola vez** en `main.dart` antes de `runApp`.

## Convenciones de código

- `const` en todos los constructores y widgets donde sea posible.
- Nombres de archivos: `snake_case.dart`.
- Una clase/widget por archivo.
- Los widgets no contienen lógica de negocio; solo construyen UI y despachan eventos.
- Inyectar dependencias por constructor; nunca instanciar servicios dentro de un widget.

## Testing

- Mocks con `mocktail` (no `mockito`).
- Tests de Bloc/Cubit con `bloc_test`.
- Los widget tests envuelven el widget bajo prueba en `MultiBlocProvider` con mocks.
- Un test no debe depender del estado de otro test (sin estado compartido entre tests).

## Rutas de navegación

```
/                    Inbox
/article/:id         Lector (desde Inbox)
/archive             Archivo
/archive/:id         Lector (desde Archivo)
/favorites           Favoritos
/favorites/:id       Lector (desde Favoritos)
/sources             Fuentes
/sources/add         Agregar fuente
```

## Reglas de negocio clave

- Artículo se marca como leído automáticamente al abrirlo.
- Artículos leídos > 30 días se eliminan (salvo favoritos).
- Artículos no leídos > 30 días se archivan (no se eliminan).
- Favoritos nunca se eliminan automáticamente.
- Contenido truncado: `contentHtml == null || contentHtml.length < 500`.
- Timeout por feed durante sync: 10 segundos. Un fallo no interrumpe las demás fuentes.

## Documentos de referencia

- `PRD.md` — requisitos del producto
- `USER_STORIES.md` — historias de usuario con criterios de aceptación
- `SOLUTION_SPEC.md` — decisiones técnicas detalladas
