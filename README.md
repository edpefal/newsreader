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

## Feeds generados por email (setup de infraestructura)

Para newsletters sin RSS/Atom, la app puede generar una dirección de email única; cualquier correo que llegue se convierte en un item de un feed RSS servido por Supabase. Requiere un setup manual único, fuera del código, antes de que el flujo funcione:

1. **Dominio propio**: un subdominio dedicado a esto (ej. `inbox.tudominio.com`). No hace falta registrar uno nuevo si ya tenés uno.
2. **Cuenta en [ForwardEmail.net](https://forwardemail.net)**. El plan gratuito bloquea dominios "recién creados o transferidos" en registradores como Namecheap, GoDaddy y Hostgator (política anti-abuso) — en la práctica hace falta el plan **Enhanced Protection ($3 USD/mes)** para que funcione con un dominio nuevo. El proveedor de email entrante está detrás de una abstracción (`supabase/functions/inbound-email/providers/`) para poder reemplazarlo sin reescribir la lógica de negocio si esto cambia.
3. **DNS del dominio**, agregar:

   | Tipo | Valor | Nota |
   |------|-------|------|
   | MX | `mx1.forwardemail.net` | prioridad 10 |
   | MX | `mx2.forwardemail.net` | prioridad 10 |
   | TXT | `v=spf1 include:spf.forwardemail.net -all` | SPF |

   El webhook **no** se configura como TXT record (ForwardEmail lo desaconseja: los TXT son legibles públicamente y expondrían el secreto). En cambio, se crea un alias catch-all (`*`) en el dashboard de ForwardEmail (Domains → tu dominio → Aliases), con la URL del webhook en el campo "Forwarding Recipients":
   ```
   https://<project-ref>.supabase.co/functions/v1/inbound-email?secret=<secreto>
   ```

4. **Secrets de Supabase** (`supabase secrets set`):
   - `EMAIL_DOMAIN` — el dominio registrado en el paso 1, usado por `create-feed` para armar la dirección `<uuid>@<dominio>`.
   - `FORWARDEMAIL_WEBHOOK_SECRET` — el mismo secreto usado en el TXT record del paso 3, validado por `inbound-email`.
5. **Migración y deploy**:
   ```bash
   supabase db push                              # aplica supabase/migrations/
   supabase functions deploy create-feed         # requiere JWT (la llama la app con la anon key)
   supabase functions deploy inbound-email --no-verify-jwt  # la llama ForwardEmail, sin JWT
   supabase functions deploy feed --no-verify-jwt            # la llama el parser RSS, sin JWT
   ```

Si en algún momento hace falta migrar de dominio, repetir los pasos 1, 3 y 4 (actualizar `EMAIL_DOMAIN` y el TXT del nuevo dominio) — el esquema de datos y las edge functions no cambian.

Ver `openspec/changes/archive/*-email-to-rss-generated-feeds/design.md` (una vez archivado) para el diseño completo: esquema de tablas, formato del payload de ForwardEmail, y las decisiones de autenticación/retención.

## Inicio rápido

```bash
flutter pub get
flutter run
```

> Requiere Flutter 3.x con Dart SDK ^3.8.1.
