## Why

Reevo quiere llegar a macOS (change posterior `add-macos-support`), pero el SDK de Flutter de Superwall solo soporta iOS y Android, y su paywall remoto no se puede mostrar en una app de Mac. `purchases_flutter` (RevenueCat) sí soporta macOS, aunque `purchases_ui_flutter` no. Tener dos SDK de suscripción en la misma base de código duplicaría las fuentes de verdad, así que se migra todo a RevenueCat primero, en iOS, con el paywall como un widget propio de Flutter que luego se reutiliza en Mac.

Es el momento de hacerlo: no hay suscriptores reales (en prod, `entitlements` tiene una sola fila inactiva, de pruebas), así que el corte puede ser limpio y sin migrar compradores.

## What Changes

- Se reemplaza `superwallkit_flutter` por `purchases_flutter`: nuevo `RevenueCatSubscriptionStatusProvider` que mantiene `isSubscribed` a partir de `CustomerInfo` (estado inicial de la caché del SDK + listener), `identify`/`reset` con `logIn`/`logOut`, y las operaciones de ofertas, compra y restauración. **BREAKING** (interno): `SubscriptionStatusProvider` pierde `showPaywall`.
- Nuevo paywall propio de Flutter (`PaywallScreen` + `PaywallCubit` en `presentation/paywall/`) mostrado por un `PaywallLauncher` (interfaz en `core/subscription/`, implementación a nivel de app): ruta modal a pantalla completa por debajo de 840dp y diálogo centrado a partir de 840dp. Muestra los planes mensual y anual con precios de la tienda, la prueba gratis de 7 días del plan anual solo a quien es elegible, texto legal de renovación automática, enlaces a Términos y Privacidad, y "Restaurar compras". Los tres features que hoy llaman a `showPaywall` (Ajustes, resumen de artículo, lector) pasan a recibir un `PaywallLauncher`.
- Ajustes añade "Restaurar compras" y "Gestionar suscripción" (abre la página de suscripciones de Apple).
- Nueva Edge Function `revenuecat-webhook`: valida el valor de la cabecera `Authorization`, y ante cualquier evento consulta el estado del entitlement `pro` por la API REST de RevenueCat y hace upsert en `entitlements`, sin interpretar tipos de evento. Ignora con 200 a los usuarios que no existen en su proyecto de Supabase.
- Nueva Edge Function `sync-entitlement` (con JWT del usuario): consulta a RevenueCat y escribe `entitlements`. El cliente la llama tras una compra o restauración exitosa, antes de ejecutar la acción posterior, para que `summarize-article` no responda 403 por la carrera con el webhook.
- El borrado de cuenta avisa, solo a suscriptores, de que la suscripción de Apple no se cancela (con enlace a gestionarla) y `delete-account` borra al cliente en RevenueCat (un fallo se registra en Sentry y no bloquea el borrado).
- Nuevos eventos de PostHog: `paywall_viewed` (con `trigger`), `paywall_dismissed`, `purchase_completed` (con `plan` e `is_trial`), `purchase_failed` (con código de error) y `restore_completed`.
- Se retira Superwall del cliente (`pubspec.yaml`, pods, configuración en `main.dart`, `SuperwallSubscriptionStatusProvider`). `superwall-webhook` **no** se borra en este change: queda desplegado e inerte hasta cumplir su criterio de retiro (ver design). Android queda sin compras (fuera de alcance).
- Se actualiza `CLAUDE.md` (tabla de abstracciones, arquitectura y reglas de negocio que citan Superwall).

## Capabilities

### New Capabilities
- `subscription-paywall`: paywall propio de Flutter y su presentación adaptativa (`PaywallLauncher`), planes y precios de la tienda, prueba gratis de 7 días del plan anual para usuarios elegibles, texto legal y enlaces, restaurar compras y gestionar suscripción en Ajustes, estado de error cuando las ofertas no cargan, y los eventos de PostHog del paywall.

### Modified Capabilities
- `subscription-entitlements`: la identificación del usuario pasa a RevenueCat, el webhook pasa a `revenuecat-webhook` (consulta del estado en lugar de interpretar eventos, dos webhooks para `reevo` y `reevo-dev`), y se agrega `sync-entitlement` tras comprar o restaurar.
- `annual-subscription-plan`: el paywall que ofrece ambos planes es el propio de Flutter, y el plan anual incluye oferta de introducción de 7 días.
- `article-summaries`: las referencias al paywall de Superwall pasan al `PaywallLauncher` (mismo flujo post-compra).
- `account-deletion`: aviso previo para suscriptores y borrado del cliente en RevenueCat.
- `web-legal-pages`: los enlaces estables de Términos y Privacidad se referencian desde el paywall de la app, no desde el de Superwall.
- `settings-account-status`: el botón de upgrade abre el paywall de la app, y Ajustes añade Restaurar compras y Gestionar suscripción.
- `product-analytics`: se agregan los eventos del paywall.

## Impact

- **Cliente:** `pubspec.yaml` (quita `superwallkit_flutter`, agrega `purchases_flutter`), `ios/` (pods, capabilities de In-App Purchase), `lib/main.dart`, `lib/core/di/injection.dart`, `lib/core/subscription/`, nuevo `lib/presentation/paywall/`, `settings_screen.dart`, `article_summary_bottom_sheet.dart`, `reader_screen.dart`, `.arb` en los 3 idiomas, y la clave pública de RevenueCat en `AppConfig`.
- **Servidor:** nuevas funciones `revenuecat-webhook` y `sync-entitlement`, cambio en `delete-account`, `supabase/config.toml`, secrets (clave REST de RevenueCat y secret del webhook) en `reevo` y `reevo-dev`. La tabla `entitlements` y el gate de `summarize-article` y `generate-daily-summaries` no cambian.
- **Servicios externos (a cargo del usuario):** proyecto de RevenueCat, entitlement `pro`, offering con ambos planes, credenciales de App Store Connect, oferta de introducción de 7 días en el producto anual, dos webhooks, y — solo cuando la versión nueva esté en `READY_FOR_DISTRIBUTION` — mover la URL de notificaciones de Apple a RevenueCat y archivar el campaign de Superwall.
- **Despliegue:** funciones a `reevo` y `reevo-dev`. La regla de CLAUDE.md sobre servidor y clientes ya publicados aplica al retiro de `superwall-webhook`.
