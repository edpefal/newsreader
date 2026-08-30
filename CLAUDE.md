# Reevo — Instrucciones para Claude

## Comunicación con el usuario

Dirigirse al usuario siempre en **español latinoamericano neutro, con tuteo** ("tienes", "puedes", "avísame", "aquí"), nunca en voseo rioplatense/argentino ("tenés", "podés", "avisame", "acá"). Aplica a toda respuesta conversacional de Claude en el chat, sin excepción.

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
flutter gen-l10n                         # regenerar AppLocalizations tras tocar lib/l10n/*.arb
```

Correr `flutter analyze` después de cualquier cambio de código. No dejar warnings sin resolver.

## Proyectos de Supabase

Existen dos proyectos de Supabase, ambos bajo la misma organización:

| Proyecto | Reference ID | Uso |
|----------|--------------|-----|
| `reevo` | `avyaxzhdilhufyimrzzb` | Producción — es el que queda linkeado por defecto en el repo (`supabase/.temp/project-ref`) |
| `reevo-dev` | `xgwnxhpdcrghrtdbrmpn` | Desarrollo |

Al desplegar una Edge Function (`supabase functions deploy <nombre>`), por defecto solo se despliega al proyecto linkeado (`reevo`, prod). Para desplegar también a `reevo-dev`, agregar `--project-ref xgwnxhpdcrghrtdbrmpn` sin cambiar el link del repo. Antes de dar por terminado un cambio de Edge Function, confirmar con el usuario a cuál(es) de los dos proyectos hay que desplegarlo — no asumir que solo uno basta.

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

## Testing

- Mocks con `mocktail` (no `mockito`).
- Tests de Bloc/Cubit con `bloc_test`.
- Los widget tests envuelven el widget bajo prueba en `MultiBlocProvider` con mocks.
- Un test no debe depender del estado de otro test (sin estado compartido entre tests).
- Las pruebas manuales en simulador/dispositivo (correr la app, navegar, tomar screenshots) las hace el usuario. No lancees `flutter run` en un simulador ni automatices taps para verificar cambios de UI, salvo que el usuario lo pida explícitamente.

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
- No hay archivado ni borrado automático por antigüedad: los artículos no leídos permanecen en el inbox indefinidamente, y los leídos permanecen en "Leídos" indefinidamente (ver `openspec/specs/article-lifecycle/spec.md`).
- Favoritos nunca se eliminan automáticamente.
- Contenido truncado: `contentHtml == null || contentHtml.length < 500`.
- Timeout por feed durante sync: 10 segundos. Un fallo no interrumpe las demás fuentes.

## Flujo de trabajo

Todos los features se implementan por medio de OpenSpec (`/opsx:propose` → `/opsx:apply` → `/opsx:archive`), sin excepción, aunque el scope parezca chico.

**`main` está protegida: nunca se pushea ni se mergea código directo ahí.** El flujo correcto es:

1. Crear una rama nueva para el change (ej. `add-nombre-del-change`).
2. Implementar en esa rama (`/opsx:apply`), corriendo `flutter analyze` y `flutter test` localmente antes de subir.
3. Una vez que las pruebas locales pasan, pushear la rama y abrir un PR contra `main`.
4. Esperar a que el check de CI (`analyze-and-test` en GitHub Actions) pase en el PR — `main` tiene branch protection que exige ese check en verde antes de habilitar el merge.
5. Recién ahí mergear el PR y archivar el change de OpenSpec (`/opsx:archive`) — el archive también se sube por PR, no directo a `main`.

Nunca usar `git push` directo a `main` ni `--no-verify`/bypass de branch protection salvo que el usuario lo pida explícitamente.

## Commits

Seguir [Conventional Commits](https://www.conventionalcommits.org/): `<tipo>: <descripción>` en minúscula, sin punto final, en español.

Tipos usados en este proyecto: `feat`, `fix`, `chore`. (`docs`, `refactor`, `test`, `perf` quedan disponibles si aplica, pero no se han usado todavía.)

- Un commit por cambio lógico independiente — si un change de OpenSpec tocó varias áreas no relacionadas, separar en varios commits en vez de uno solo mezclado.
- El cuerpo (opcional, después de una línea en blanco) explica el *por qué*, no el *qué* — el diff ya muestra el qué.

```
feat: mostrar imagen destacada del feed en la lista de artículos
fix: cascadear el borrado de una fuente a sus artículos en Supabase
chore: bump versión a 1.6.0+7
```

## Documentos de referencia

- `PRD.md` — requisitos del producto
- `USER_STORIES.md` — historias de usuario con criterios de aceptación
- `SOLUTION_SPEC.md` — decisiones técnicas detalladas
