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

## Arquitectura: Clean Architecture

Tres capas. Las dependencias solo apuntan hacia adentro:

```
Presentation → Domain ← Data
```

- **`domain/`** — entidades y use cases. Sin Flutter, sin librerías de terceros.
- **`data/`** — implementaciones de repositorios, modelos Hive, datasources.
- **`presentation/`** — Blocs/Cubits, pantallas, widgets.
- **`core/`** — abstracciones de librerías, DI, utilidades sin estado.

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
- Nunca llamar `Hive.box()` fuera de las clases datasource en `data/datasources/local/`.
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
