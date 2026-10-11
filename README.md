# Reevo

Una app Flutter para centralizar tus fuentes RSS/Atom y newsletters fuera del correo electrónico. Lee artículos en un lector limpio, guarda favoritos y recibe un resumen diario.

## Características

- **Inbox** — artículos no leídos ordenados por fecha, con badge de conteo, pull-to-refresh y tarjeta del resumen de hoy
- **Lector** — contenido HTML con ancho de texto limitado (~680pt) y acceso al artículo web vía WebView
- **Favoritos y Leídos** — favoritos permanentes; los artículos leídos pasan a "Leídos" y no se borran ni archivan por antigüedad
- **Fuentes** — agregar por URL (autodetección de feed), importar OPML, feeds generados a partir de newsletters por email, editar nombre y eliminar
- **Resúmenes diarios** — los genera el servidor para cada usuario elegible (suscripción activa, o los lunes sin suscripción), agrupados por fuente; lista y detalle en la tab Resúmenes
- **Resumen con IA de un artículo y menciones** — vía Edge Functions (Gemini, Google Books, iTunes), con presupuesto diario por usuario y acceso según suscripción
- **Sincronización offline-first** — Hive es la copia local; los cambios se suben de inmediato a Supabase (best-effort) y `SyncUserData` reconcilia entre dispositivos
- **Cuenta** — login con Google o Apple, exportar datos (JSON/OPML) y borrar cuenta
- **Suscripción** — paywall con Superwall
- **Idiomas** — inglés, español y francés (`flutter_localizations` + `.arb`)
- **iPad** — navegación con `NavigationRail` y master-detail de 2 paneles en anchos ≥840dp
- **Tema** — light/dark/sistema, con acento óxido (`ReevoAccent`)

## Stack

| Capa | Tecnología |
|------|-----------|
| State management | `flutter_bloc` / Cubit |
| Navegación | `go_router` (`StatefulShellRoute` + `ShellRoute` por tab) |
| Base de datos local | `hive_ce` |
| Backend | Supabase (auth, Postgres, Edge Functions en Deno) |
| Auth | `supabase_flutter`, `google_sign_in`, `sign_in_with_apple` |
| Suscripciones | `superwallkit_flutter` |
| Observabilidad | `sentry_flutter`, `posthog_flutter` |
| IA | Gemini (Edge Functions `summarize-article` y `generate-daily-summaries`) |
| Renderizado HTML | `flutter_widget_from_html`, `webview_flutter` |
| DI | `get_it` |
| i18n | `flutter_localizations`, `intl` |

Los feeds RSS/Atom los parsea el servidor (Edge Function `sync-feeds`); el cliente solo dispara el fetch.

## Arquitectura

Clean Architecture por features: las dependencias apuntan hacia adentro (`presentation → domain ← data`) y un feature nunca importa de otro. Las librerías de infraestructura se usan solo a través de abstracciones de `core/`.

```
lib/
├── core/            # infraestructura compartida: ai, auth, config, data (Hive),
│                    # di, domain, email_feed, errors, feed, navigation, network,
│                    # observability, opml, sharing, subscription, sync, theme,
│                    # utils, widgets
├── features/        # account, archive, article_summary, auth, favorites, inbox,
│                    # maintenance, reader, settings, sources, summaries, sync
│   └── <feature>/
│       ├── domain/usecases/
│       └── presentation/   # Cubit, screens y widgets
├── l10n/            # app_en.arb, app_es.arb, app_fr.arb
└── presentation/    # App widget, router, AppTheme y ThemeCubit
supabase/
├── functions/       # sync-feeds, generate-daily-summaries, summarize-article,
│                    # enrich-mentions, create-feed, feed, inbound-email,
│                    # delete-account, superwall-webhook
└── migrations/
openspec/            # specs y changes (flujo de trabajo de la app)
```

Las reglas completas (abstracciones, Hive, offline-first, i18n, iPad) están en `CLAUDE.md`.

## Flujo de trabajo

Cada feature se implementa con OpenSpec (`/opsx:propose` → `/opsx:apply` → `/opsx:archive`) en una rama propia. `main` está protegida: los cambios entran por PR y con el check `analyze-and-test` en verde.

## Tests

Unitarios (cubits, casos de uso, l10n) y de widgets, con `mocktail` y `bloc_test`:

```bash
flutter test               # todos
flutter test test/unit/    # solo unitarios
flutter test test/widget/  # solo de widgets
flutter analyze            # lint
```

Las Edge Functions tienen sus propios tests de Deno:

```bash
(cd supabase/functions/<nombre> && deno test --allow-env)
```

## CI/CD

- **CI (GitHub Actions)**: `.github/workflows/ci.yml` corre `flutter analyze` y `flutter test` automáticamente en cada push y pull request contra `main`. No requiere configuración adicional.
- **CD a TestFlight (Codemagic)**: `codemagic.yaml` define el workflow `iOS TestFlight`, que compila, firma y sube un build de producción (`--dart-define=APP_ENV=prod`) al grupo interno de TestFlight. Es de **trigger manual** — no corre en cada push, para no consumir minutos del free tier de Codemagic.

  Para correr un build manual:
  1. Entrar a [codemagic.io](https://codemagic.io), abrir la app `Reevo`.
  2. En el workflow **iOS TestFlight**, click en **Start new build**, elegir la rama (normalmente `main`).
  3. El build tarda ~10-20 minutos. Al terminar, aparece en TestFlight interno (App Store Connect → TestFlight → grupo interno) y queda instalable en los dispositivos de prueba agregados a ese grupo.

  Credenciales necesarias (configuradas una sola vez en la UI de Codemagic, no viven en el repo):
  - Integración de App Store Connect API key (nombre `reevo_asc_api_key`) con acceso a `com.artlab.reevo`, para firma automática y resolución del build number.
  - Variable de entorno `CERTIFICATE_PRIVATE_KEY` (grupo `appstore_credentials`, marcada Secret) con la private key del certificado de distribución iOS.

  El build se marca con `testFlightInternalTestingOnly: true` al firmar, así que queda disponible automáticamente para todos los testers internos de la cuenta (Apple no permite asignar builds a grupos internos por API — solo a grupos externos vía `beta_groups`).

## Feeds generados por email (setup de infraestructura)

Para newsletters sin RSS/Atom, la app puede generar una dirección de email única; cualquier correo que llegue se convierte en un item de un feed RSS servido por Supabase. Requiere un setup manual único, fuera del código, antes de que el flujo funcione:

1. **Dominio propio**: un subdominio dedicado a esto (ej. `inbox.tudominio.com`). No hace falta registrar uno nuevo si ya tienes uno.
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
5. **Migración y deploy**: las migraciones se aplican con `apply_migration` (MCP de Supabase), no con `supabase db push` (ver `CLAUDE.md`). Las funciones:
   ```bash
   supabase functions deploy create-feed         # requiere JWT (la llama la app con la anon key)
   supabase functions deploy inbound-email --no-verify-jwt  # la llama ForwardEmail, sin JWT
   supabase functions deploy feed --no-verify-jwt            # la llama el parser RSS, sin JWT
   ```

Si en algún momento hace falta migrar de dominio, repetir los pasos 1, 3 y 4 (actualizar `EMAIL_DOMAIN` y el TXT del nuevo dominio) — el esquema de datos y las edge functions no cambian.

Ver `openspec/changes/archive/*-email-to-rss-generated-feeds/design.md` para el diseño completo: esquema de tablas, formato del payload de ForwardEmail, y las decisiones de autenticación/retención.

## Inicio rápido

```bash
flutter pub get
flutter run                              # APP_ENV=dev por defecto (proyecto Supabase reevo-dev)
flutter run --dart-define=APP_ENV=prod   # apunta a producción (reevo)
```

Tras cambiar modelos de Hive: `dart run build_runner build`. Tras tocar `lib/l10n/*.arb`: `flutter gen-l10n`.

> Requiere Flutter 3.x con Dart SDK ^3.8.1.
