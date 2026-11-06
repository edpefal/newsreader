## 1. Configuración externa (a cargo del usuario)

- [x] 1.1 Crear el proyecto en RevenueCat, conectar App Store Connect (clave de In-App Purchase y API key) y registrar la app iOS (`com.artlab.reevo`)
- [x] 1.2 Importar los productos mensual y anual existentes, crear el entitlement `pro` y un offering predeterminado con ambos paquetes
- [x] 1.3 Configurar en App Store Connect la oferta de introducción de 7 días gratis solo en el producto anual
- [x] 1.4 Crear la clave secreta de la API REST de RevenueCat y la llave pública de iOS (`appl_…`)
- [x] 1.5 Dar de alta dos webhooks en RevenueCat (a `revenuecat-webhook` de `reevo` y de `reevo-dev`, sandbox y producción) con su valor de autorización
- [x] 1.6 Guardar `REVENUECAT_SECRET_API_KEY` y `REVENUECAT_WEBHOOK_AUTH` como secrets en `reevo` y `reevo-dev`

## 2. Servidor: estado de entitlement y webhook

- [x] 2.1 Crear `supabase/functions/revenuecat-webhook/entitlement_state.ts`: consulta `GET /v1/subscribers/{id}` y devuelve si el entitlement `pro` está vigente (incluye periodo de prueba), con tests de Deno (vigente, expirado, prueba, sin entitlement, error de API)
- [x] 2.2 Implementar `revenuecat-webhook/index.ts`: validar `Authorization` en tiempo constante (401), ignorar con 200 los ids anónimos, sin `app_user_id` y usuarios inexistentes en `auth.users`, consultar el estado y hacer upsert en `entitlements`, y responder 500 si falla RevenueCat; con tests de Deno
- [x] 2.3 Implementar `sync-entitlement` (JWT requerido, `user_id` tomado del token, copia de `entitlement_state.ts`) con tests de Deno, incluido que ignora un `user_id` del body
- [x] 2.4 Registrar `revenuecat-webhook` (sin JWT) y `sync-entitlement` (con JWT) en `supabase/config.toml`
- [x] 2.5 Extender `delete-account` para borrar al cliente en RevenueCat sin bloquear el borrado si falla (reporte a Sentry sin PII) y cubrirlo con un test
- [x] 2.6 Correr `(cd supabase/functions/<nombre> && deno test --allow-env)` en las tres funciones
- [ ] 2.7 Desplegar las tres funciones a `reevo-dev`, verificar con una compra sandbox, y confirmar con el usuario antes de desplegar a `reevo` (prod)

## 3. Cliente: proveedor de suscripciones

- [x] 3.1 Reemplazar `superwallkit_flutter` por `purchases_flutter` en `pubspec.yaml`, verificar el mínimo de iOS del `Podfile` y regenerar pods
- [x] 3.2 Agregar la llave pública de RevenueCat por plataforma a `AppConfig` (sin llave en Android)
- [x] 3.3 Ampliar `SubscriptionStatusProvider` (ofertas, comprar, restaurar) y quitar `showPaywall`
- [x] 3.4 Implementar `RevenueCatSubscriptionStatusProvider`: estado inicial desde la caché del SDK, listener de `CustomerInfo`, `identify` con `logIn`, `reset` con `logOut`, y modo sin compras en Android
- [x] 3.5 Agregar a `CloudSyncClient` (impl Supabase) la llamada a `sync-entitlement` y un use case que la invoque tras comprar o restaurar
- [x] 3.6 Actualizar `main.dart` (`Purchases.configure` sin bloqueo de red, eliminar `Superwall.configure` y la llave) y `injection.dart`
- [x] 3.7 Eliminar `SuperwallSubscriptionStatusProvider` y cualquier referencia a Superwall en el cliente
- [x] 3.8 Tests unitarios del provider con el SDK simulado y de la identificación/desvinculación en login y logout

## 4. Cliente: paywall propio

- [x] 4.1 Definir `PaywallLauncher` en `core/subscription/` e inyectarlo por constructor en Ajustes, el bottom sheet de resumen y el lector
- [x] 4.2 Crear `PaywallCubit` (estados: cargando, ofertas listas, error con reintento, comprando, restaurando) con tests de `bloc_test`
- [x] 4.3 Crear `PaywallScreen` con los planes y precios de la tienda, prueba gratis solo si es elegible, texto de renovación y cobro tras la prueba, enlaces a Términos y Privacidad y "Restaurar compras"
- [x] 4.4 Implementar `AppPaywallLauncher`: ruta modal a pantalla completa bajo 840dp y diálogo centrado desde 840dp, devolviendo `true` si quedó suscrito; verificando que sirve como panel embebido y no duplica chrome
- [x] 4.5 Migrar los tres puntos de entrada (`settings_screen`, `article_summary_bottom_sheet`, `reader_screen`) al launcher conservando el flujo post-compra
- [x] 4.6 Agregar "Restaurar compras" y "Gestionar suscripción" a Ajustes (esta última solo para suscriptores) abriendo la página de suscripciones de Apple con `ExternalLinkLauncher`
- [x] 4.7 Emitir los eventos `paywall_viewed`, `paywall_dismissed`, `purchase_completed`, `purchase_failed` y `restore_completed` por `TelemetryClient`, sin registrar la cancelación como fallo
- [x] 4.8 Agregar todas las cadenas nuevas a `app_en.arb`, `app_es.arb` (español neutro con tuteo) y `app_fr.arb`, y correr `flutter gen-l10n`
- [x] 4.9 Widget tests del paywall (estados, ancho <840dp y ≥840dp) y de los nuevos controles de Ajustes

## 5. Cliente: borrado de cuenta

- [x] 5.1 Mostrar en la confirmación de borrado el aviso de suscripción (solo si `isSubscribed`) con acción para abrir la gestión de suscripciones de Apple, sin bloquear el borrado
- [x] 5.2 Agregar las cadenas del aviso en los 3 idiomas y tests de widget de ambos casos (con y sin suscripción)

## 6. Documentación y specs

- [x] 6.1 Actualizar `CLAUDE.md` (tabla de abstracciones, `core/subscription`, reglas de negocio y orden de despliegue) para reemplazar Superwall por RevenueCat
- [x] 6.2 Actualizar el `Purpose` del spec principal `subscription-entitlements` (menciona Superwall) al archivar
- [x] 6.3 Correr `openspec validate migrate-to-revenuecat --strict`

## 7. Verificación

- [x] 7.1 `flutter analyze` sin warnings y `flutter test` en verde
- [ ] 7.2 Build de TestFlight con RevenueCat: compra mensual, compra anual con prueba, cancelar durante la prueba, restauración, expiración, y que el resumen de un artículo funcione justo después de comprar (a cargo del usuario)
- [ ] 7.3 Probar el borrado de cuenta con y sin suscripción y la presentación del paywall en iPhone y en iPad (a cargo del usuario)
- [ ] 7.4 Tras `READY_FOR_DISTRIBUTION`: mover la URL de notificaciones de Apple a RevenueCat y archivar el campaign de Superwall (a cargo del usuario)
- [ ] 7.5 Documentar el criterio de retiro de `superwall-webhook` (ninguna 1.9.x/1.10.x activa en PostHog en 30 días) y abrir su change/PR posterior
