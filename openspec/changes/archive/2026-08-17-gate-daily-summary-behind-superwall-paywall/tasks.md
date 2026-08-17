## 1. Base de datos

- [x] 1.1 Nueva migración: tabla `entitlements` (`user_id uuid references auth.users`, `is_active boolean not null default false`, `updated_at timestamptz not null default now()`), con RLS habilitado.
- [x] 1.2 Policy `entitlements_select_own`: el usuario puede `SELECT` solo su propia fila (`user_id = auth.uid()`).
- [x] 1.3 Sin policy de `INSERT`/`UPDATE` para roles no privilegiados — solo `service_role` (usado por el webhook) puede escribir.

## 2. Edge Function: superwall-webhook

- [x] 2.1 Verificar contra la documentación vigente de Superwall (superwall.com/docs) la forma real del payload y los nombres de eventos de suscripción antes de implementar — no asumir lo descripto en design.md al pie de la letra.
- [x] 2.2 Crear `supabase/functions/superwall-webhook/index.ts`: valida la firma del request con `SUPERWALL_WEBHOOK_SECRET`; si es inválida, responde 401 sin tocar `entitlements`.
- [x] 2.3 Parsear el evento y hacer upsert en `entitlements` (`is_active = true` para alta/renovación; `is_active = false` para cancelación/expiración/reembolso), usando `service_role`.
- [x] 2.4 Webhook de Superwall → Supabase configurado (2026-08-13). Encontrado y corregido de paso: `superwall-webhook` **no estaba desplegada en prod** (`avyaxzhdilhufyimrzzb`), solo en dev — se desplegó (`verify_jwt: false`, igual que dev). Se crearon dos endpoints en Superwall (`mcp__superwall__create_webhook_endpoint`, proyecto `28726`) con `filter_types` cubriendo los eventos que maneja `entitlement_event.ts` (`initial_purchase`, `renewal`, `uncancellation`, `non_renewing_purchase`, `product_change`, `expiration`, `billing_issue`, `subscription_paused`, `cancellation`): uno a la URL de prod, otro a la de dev. Cada uno devolvió su propio `secret` (`whsec_...`), seteado vía `supabase secrets set SUPERWALL_WEBHOOK_SECRET=... --project-ref <ref>` en cada proyecto y confirmado con `supabase secrets list`. **No confundir con el webhook Apple → Superwall (App Store Server Notifications V2), que es un paso distinto y ya está hecho — ver sección 8.4.**

## 3. Backend: chequeo de entitlement en summarize-articles

- [x] 3.1 Después de validar la sesión (`require-authenticated-session-for-summary-and-email-feed`), consultar `entitlements` para el `user_id` obtenido.
- [x] 3.2 Si no hay fila o `is_active = false`, responder con un error de suscripción requerida (403) sin invocar a Gemini.

## 4. Cliente: SDK de Superwall

- [x] 4.1 Agregar la dependencia del SDK de Superwall a `pubspec.yaml`.
- [x] 4.2 `lib/core/subscription/subscription_status_provider.dart`: abstracción (`bool get isSubscribed` o similar, más el método para mostrar el paywall, más `reset()` para logout).
- [x] 4.3 `lib/core/subscription/superwall_subscription_status_provider.dart`: implementación concreta con el SDK de Superwall.
- [x] 4.4 Registrar la nueva abstracción en `lib/core/di/injection.dart`.
- [x] 4.5 Tras un login exitoso, identificar al usuario en Superwall con su `user_id` de Supabase Auth. Tras un logout/borrado de cuenta, llamar `reset()` (gap encontrado y corregido durante testing — Superwall nunca desvinculaba al usuario anterior).

## 5. Cliente: gate del botón de generar resumen

- [x] 5.1 En `SummariesScreen`/`SummariesCubit`: antes de disparar `generateTodaySummary()`, chequear `SubscriptionStatusProvider.isSubscribed`; si es `false`, mostrar el paywall de Superwall en vez de generar.
- [x] 5.2 Si el usuario completa la compra desde el paywall, disparar la generación automáticamente a continuación (sin que tenga que tocar el botón una segunda vez).

## 6. Tests

- [x] 6.1 Unit test: `summarize-articles` (o su lógica de entitlement extraída a una función testeable) rechaza sin `is_active = true`.
- [x] 6.2 Test: `SummariesCubit` muestra el paywall en vez de generar cuando no hay suscripción activa. El gate vive en el cubit, no en `SummariesScreen`.
- [x] 6.3 Test: `SummariesCubit` dispara la generación automáticamente cuando el usuario completa la compra desde el paywall.

## 7. Verificación

- [x] 7.1 Correr `flutter analyze` sin warnings.
- [x] 7.2 Correr `flutter test` y confirmar que toda la suite pasa.
- [x] 7.3 Probado de punta a punta contra el proyecto Supabase de dev (2026-08-16): compra sandbox completada, `superwall-webhook` actualizó `entitlements.is_active = true` (~4 min de delay, normal en sandbox), y `summarize-articles` generó el resumen correctamente. En el camino se encontraron y arreglaron dos bugs reales no relacionados al gate en sí: `gemini-2.5-flash` había sido retirado por Google (404) — actualizado a `gemini-3.7-flash` en dev y prod; y un 503 transitorio de sobrecarga del modelo recién lanzado, que se resolvió solo al reintentar.

## 8. Infraestructura externa (App Store Connect + Superwall) — EN CURSO

Estado detallado al 2026-08-13, para retomar en otra sesión sin perder contexto.

### 8.1 Play Store — descartado
- [x] Se intentó Google Play Console para Internal Testing; la cuenta de developer del usuario fue cerrada por Google. **Se abandonó la vía Android y se sigue solo por iOS/TestFlight.**

### 8.2 App Store Connect — signing y build
- [x] Apple Developer Program activo, ficha de app creada en App Store Connect (`Reevo Digest`, bundle id `com.artlab.reevo`, Apple app id `6761575130`), ya con builds subidos a TestFlight.
- [x] Keystore/signing de **Android** release configurado (`android/app/upload-keystore.jks` + `android/key.properties`, fuera de git) — `flutter build appbundle` funciona. (Nota: sin cuenta de Play Console esto queda sin uso inmediato, pero el signing en sí está listo si se retoma Android más adelante.)
- [x] Signing de **iOS** ya estaba configurado (Automatic, `DEVELOPMENT_TEAM = HK5V7DF66Q`) desde antes de esta sesión (Sign in with Apple).
- [x] `minSdk` Android → 26 y iOS deployment target → 14.0 (ambos requeridos por `superwallkit_flutter`).

### 8.3 App Store Connect — producto de suscripción
- [x] Subscription Group "Reevo Premium" creado.
- [x] Producto mensual creado: **Product ID `com.artlab.reevo.premium.monthly`**, ASC subscription id `6800859348`, subscription group id `22305683`.
- [x] Localización en/es-MX completa (Display Name "Reevo Premium", Description "AI-powered features for your daily reading" / "Funciones con IA para tu lectura diaria" — texto genérico a propósito, para cubrir futuras features de IA además del resumen diario).
- [x] Precio cargado (confirmado por el usuario, 175 territorios con price schedule vía API).
- [x] App Store Review Screenshot subido (2026-08-13): captura de la pantalla de Resúmenes (simulador iOS) subida vía `superwall asc` (reserva `POST /v1/subscriptionAppStoreReviewScreenshots` + `PUT` del binario a la URL firmada + `PATCH` con checksum). Confirmado `assetDeliveryState: COMPLETE`, imagen 1206x2622 asociada a la suscripción `6800859348`. El `state` del producto seguía en `MISSING_METADATA` justo después de subirlo — normal, Apple tarda en recalcularlo. **Verificar en la próxima sesión** con `superwall asc get /v1/subscriptions/6800859348 --json` que ya pasó a `READY_TO_SUBMIT` o similar; si sigue en `MISSING_METADATA` después de un rato, revisar si falta algo más (localización, precio) en el dashboard.
- [x] Producto **anual** movido a change aparte: `add-annual-premium-product` (2026-08-16) — no bloqueante para este change, se propuso como mejora incremental independiente.
- [x] Sandbox tester logueado en el dispositivo de prueba (confirmado por el usuario el 2026-08-14 durante la investigación del bug del paywall en blanco — a reverificar si la compra real falla por motivos de cuenta).
- [x] **Acuerdo de Aplicaciones de Pago activado en ASC** (2026-08-16) — pasó de "New" a "Active" tras completar legal entity, W-8BEN e info bancaria/fiscal. Este era el bloqueador real detrás del error `[Superwall] Trying to purchase ... but the product has failed to load` visto al tocar "Start Reevo Premium".
- [x] **App-Specific Shared Secret conectado a Superwall** (2026-08-16) — generado en ASC (Usuarios y Acceso → Integraciones) y seteado vía `mcp__superwall__update_application_settings`. Confirmado con `run_doctor`: `ios.iap_shared_secret` pasó de error a OK.

### 8.4 Superwall — dashboard y CLI
- [x] Cuenta creada (`edpefal@gmail.com`, org "Reevo", org id `26317`).
- [x] App "Reevo" creada en Superwall (project id `28726`, application id `53185`, plataforma iOS, `public_api_key: pk_JmLJquLYADH1dqyDv8aH1`).
- [x] Key pública iOS conectada en `lib/main.dart` (`Platform.isIOS` selecciona la key real; Android sigue con placeholder, no bloqueante mientras no se retome Android).
- [x] Webhook **Apple → Superwall** (App Store Server Notifications V2) configurado: URL pegada en App Store Connect → App Information → Production & Sandbox Server URL (ambos campos), usando la "Option 1 - App Store Connect" del onboarding de Superwall.
- [x] CLI `superwall` instalado globalmente y autenticado (`superwall login`, OAuth). Skills instaladas: `superwall`, `superwall-editor`, `superwall-dashboard`, `superwall-integrate`, `superwall-migrate`, `superwall-placements`, `superwall-review`, `wwdc` (via `npx skills add superwall/skills`).
- [x] Credenciales de App Store Connect conectadas al CLI de Superwall (`superwall asc keys set`, usando la key general "App Store Connect API" — Key ID `R9WBZU68N8`, Issuer ID `5dfbbcaf-7d00-4d94-bdb3-e8ba1049a854` — **no** la key específica "In-App Purchase", que Apple rechaza para este uso).
- [x] Entitlement `pro` (id `56438`) confirmado/existente.
- [x] Producto `com.artlab.reevo.premium.monthly` creado en Superwall (id `669811`), vinculado al entitlement `pro` (`superwall products create ... --entitlement 56438 --project 28726`).
- [x] Campaña "Reevo premium paywall" (id `101719`) con placement `daily_summary` (id `130686`) y audiencia "All Users" → "Show to unsubscribed users" ya configurada correctamente.
- [x] Paywall "New Paywall" (id `255832`, estado `draft`) diseñado vía `superwall-editor` (CLI + pairing code, sesión de navegador en vivo): header con logo/marca "Reevo Premium", 3 features (copy genérico para futuras funciones de IA), precio vía Liquid (`{{ products.monthly.price }}`, todavía sin resolver — depende de 8.3), botón CTA conectado a `purchase` (producto `monthly`, by-index 0), "Restore" conectado a `restore`. Producto `monthly` ya agregado al paywall (`create_product` en el editor).
- [x] **Terms/Privacy resuelto (2026-08-16)** — ver change `reevo-web-legal-pages`. Páginas nuevas en `reevo-web` (Next.js/Vercel), conectadas al `click_behavior` de los links del footer y republicado.
- [x] Split de la campaña ajustado a 100% paywall / 0% holdout (2026-08-13): resuelto vía `mcp__superwall__update_audience` sobre la audiencia `171089` (campaña `101719`), seteando `variants: [{type: treatment, paywall: 255832, percentage: 100}]`. **Corrección a la nota previa**: sí se puede hacer sin el dashboard — hay un tool MCP (`update_audience`) que reemplaza los variants directamente, no hacía falta editarlo a mano.
- [x] Paywall publicado (2026-08-13): `superwall post /v2/paywalls/255832/publish` → `version: 2`, `published_at` seteado. Confirmado que el producto `monthly` sigue vinculado correctamente (`get_products` vía editor).
- [x] **Bug del paywall en blanco — resuelto (2026-08-14).** Investigado con logs de dispositivo físico (Xcode console + `log stream`) y, la clave, el **Web Inspector de Safari apuntando al WebView del paywall en el dispositivo**. Causas encontradas, en orden:
  - Causa #1 (resuelta, 2026-08-13): la build instalada en el simulador era anterior al commit que conectó la key real de Superwall (`80b5b54`) → `Superwall.configure()` recibía 401 al pedir `/api/v1/static_config`. Fix: rebuild + reinstalar.
  - Causa #2 (resuelta, 2026-08-13): la aplicación "Reevo" en Superwall tenía `app_id` en `null`. Conectado con `mcp__superwall__update_application` (`appId: 6761575130`).
  - Causa #3 (resuelta, 2026-08-13): `subscriptionAvailability` del producto devolvía 404 — faltaba `POST /v1/subscriptionAvailabilities`. Tras esto el producto pasó a `READY_TO_SUBMIT`.
  - Causa #4 (resuelta, 2026-08-14) — **`MissingPluginException` en `streamSubscriptionStatus`**: el plugin `superwallkit_flutter` recién registra el event channel de subscription status *dentro* del handler nativo de `configure()`, pero `main.dart` llamaba a `Superwall.configure()` sin esperarlo antes de armar el DI (que se suscribe al stream). Fix en `lib/main.dart`: `Completer` que espera el `completion` callback de `configure()` antes de `setupDependencies()`.
  - Causa #5 (resuelta, 2026-08-14) — **la campaña apuntaba al paywall equivocado**: `255832` (marcado `active`/publicado) estaba **estructuralmente vacío** (`totalNodes: 0`, confirmado vía `get_basic_info` en el editor en vivo). El diseño real (header, features, precio, CTA) vivía en un borrador duplicado nunca publicado, `255848`. Repunteada la audiencia `171089` de la campaña `101719` a `255848` vía `update_audience`.
  - Causa #6 (resuelta, 2026-08-14, la más sutil) — **publicar vía API cruda no compila el documento**: `superwall post /v2/paywalls/{id}/publish` marca `status: active` y `published_at`, pero **no** dispara el build real — la `paywall_url` sigue apuntando al documento de la sesión de edición en vivo vieja, no a una versión de producción nueva. Confirmado con Web Inspector: el WebView cargaba HTML con `<div id="react-root">` vacío y sin errores de consola (nada que depurar ahí — la página "cargaba" pero nunca se poblaba). La solución fue tocar el botón **Publish real dentro de la UI del editor** (no la API), lo que generó un `sha`/document id nuevos y recién ahí `products` quedó poblado correctamente en la respuesta de `get_paywall`. Confirmado con reinstalación limpia del dispositivo (para descartar config cacheada) + Web Inspector mostrando el documento nuevo cargando bien.
  - **Aparte, sandbox tester roto**: los dos testers creados (`ederperezfalcon87@gmail.com`, `edpefal+1@gmail.com`) quedaron pidiendo una contraseña que nunca se definió (Apple cambió el flujo de alta a verificación por email en vez de contraseña directa en ASC). Sin DELETE/POST expuesto por la API para sandbox testers — hay que borrarlos y recrear desde la UI de ASC directamente. No bloqueante para el bug del blanco (ya resuelto), pero sí bloqueante para el paso 7 (probar la compra de punta a punta).
- [x] Sección 2.4 (webhook Superwall → nuestro backend) resuelta — ver arriba.

### Próximos pasos concretos, en orden, para retomar
1. ~~Sacar y subir el App Store Review Screenshot del producto (8.3)~~ — hecho 2026-08-13. Confirmar que el `state` del producto ya salió de `MISSING_METADATA`.
2. ~~Pedirle al usuario las URLs de Terms/Privacy y conectarlas en el paywall vía `superwall-editor`~~ — hecho 2026-08-16 (change `reevo-web-legal-pages`): páginas creadas en `reevo-web` (Next.js/Vercel, `https://reevo-web.vercel.app/terms` y `/privacy`) y conectadas al footer del paywall `255848` (`open-url`, `in-app-browser`), republicado desde la UI del editor.
3. ~~Ajustar el split de la campaña a 100% paywall~~ — hecho 2026-08-13 vía `update_audience`.
4. ~~Publicar el paywall~~ — hecho 2026-08-13 vía `superwall post /v2/paywalls/255832/publish`. Confirmar que el precio ya resuelve una vez que el producto en ASC salga de `MISSING_METADATA`.
5. ~~Configurar el webhook Superwall → `superwall-webhook` (Supabase) y el secret `SUPERWALL_WEBHOOK_SECRET` en dev y prod~~ — hecho 2026-08-13 (incluyó desplegar `superwall-webhook` a prod, que faltaba).
6. ~~Loguear el sandbox tester en el dispositivo/simulador de prueba~~ — confirmado.
7. **Probar compra sandbox de punta a punta (7.3) — listo para reintentar**: ya está el Acuerdo de Aplicaciones de Pago activo y el shared secret conectado (2026-08-16), los dos bloqueadores reales detrás del error "product has failed to load". Flujo a validar: tocar "Start Reevo Premium" → compra sandbox → webhook → `entitlements` → `summarize-articles` deja generar.
8. (Opcional, no bloqueante) Crear el producto anual en ASC y en Superwall si se quiere ofrecer esa opción desde el lanzamiento.
