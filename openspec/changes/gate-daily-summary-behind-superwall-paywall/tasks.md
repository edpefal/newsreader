## 1. Base de datos

- [x] 1.1 Nueva migración: tabla `entitlements` (`user_id uuid references auth.users`, `is_active boolean not null default false`, `updated_at timestamptz not null default now()`), con RLS habilitado.
- [x] 1.2 Policy `entitlements_select_own`: el usuario puede `SELECT` solo su propia fila (`user_id = auth.uid()`).
- [x] 1.3 Sin policy de `INSERT`/`UPDATE` para roles no privilegiados — solo `service_role` (usado por el webhook) puede escribir.

## 2. Edge Function: superwall-webhook

- [x] 2.1 Verificar contra la documentación vigente de Superwall (superwall.com/docs) la forma real del payload y los nombres de eventos de suscripción antes de implementar — no asumir lo descripto en design.md al pie de la letra.
- [x] 2.2 Crear `supabase/functions/superwall-webhook/index.ts`: valida la firma del request con `SUPERWALL_WEBHOOK_SECRET`; si es inválida, responde 401 sin tocar `entitlements`.
- [x] 2.3 Parsear el evento y hacer upsert en `entitlements` (`is_active = true` para alta/renovación; `is_active = false` para cancelación/expiración/reembolso), usando `service_role`.
- [ ] 2.4 Configurar en el dashboard de Superwall (Integrations → Webhooks / Svix) la URL del webhook de Supabase (`superwall-webhook`, desplegado en dev y prod) como destino de eventos de suscripción, y copiar el signing secret al secret `SUPERWALL_WEBHOOK_SECRET` de Supabase (dev y prod). **No confundir con el webhook Apple → Superwall (App Store Server Notifications V2), que es un paso distinto y ya está hecho — ver sección 8.4.** Verificado con `supabase secrets list` en ambos proyectos: `SUPERWALL_WEBHOOK_SECRET` todavía no existe en ninguno.

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
- [ ] 7.3 Probar de punta a punta contra el proyecto Supabase de dev (no prod): pagar con una compra sandbox, confirmar que el webhook actualiza `entitlements`, y que recién ahí `summarize-articles` deja generar. Bloqueado hasta terminar la sección 8.

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
- [ ] **Falta: App Store Review Screenshot.** Confirmado vía `superwall asc get /v1/subscriptions/6800859348/appStoreReviewScreenshot` → `data: null`. Es la única pieza que falta para que el producto salga de `state: MISSING_METADATA`. Sacar un screenshot de la pantalla de Resúmenes desde el simulador de iOS y subirlo en App Store Connect → Subscriptions → Resumen diario mensual → Review Screenshot. **Este era el siguiente paso concreto cuando se cortó la sesión.**
- [ ] Producto **anual** (~$29.99/año) todavía no creado en ASC — decidido en la conversación ($3.99/mes + ~$29.99/año) pero solo se creó el mensual hasta ahora. No bloqueante para probar el flujo básico.
- [ ] Sandbox tester creado por el usuario (confirmado) — falta usarlo: loguear la cuenta sandbox en Settings → App Store → Sandbox Account del simulador/dispositivo de test.

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
- [ ] **Falta: Terms/Privacy sin URL real** — los dos links del footer del paywall existen visualmente pero sin `click_behavior` conectado (no tenemos las URLs todavía). Pedirle al usuario las URLs de Términos y Privacidad.
- [ ] **Falta: ajustar el split de la campaña** a 100% paywall / 0% holdout — hoy sigue en 100% "No Paywall" (holdout). Esto **no se puede hacer por CLI ni por el editor** (confirmado en `references/setup.md` del skill `superwall-dashboard`: "Configurar audiencias / experiment splits ... hecho en el dashboard"). Hacerlo manualmente: Campaña → Placement `daily_summary` → tab del placement → arrastrar/editar el % de cada variante.
- [ ] **Falta: publicar el paywall** (sigue en `status: draft`) — botón "Publish" en el editor del dashboard, una vez que el precio resuelva y el split esté ajustado.
- [ ] Sección 2.4 (webhook Superwall → nuestro backend) sigue pendiente — ver arriba.

### Próximos pasos concretos, en orden, para retomar
1. Sacar y subir el App Store Review Screenshot del producto (8.3) → debería mover el producto a estado listo y hacer que el precio resuelva en el paywall.
2. Pedirle al usuario las URLs de Terms/Privacy y conectarlas en el paywall vía `superwall-editor`.
3. Ajustar el split de la campaña a 100% paywall (manual, dashboard).
4. Publicar el paywall.
5. Configurar el webhook Superwall → `superwall-webhook` (Supabase) y el secret `SUPERWALL_WEBHOOK_SECRET` en dev y prod (2.4).
6. Loguear el sandbox tester en el dispositivo/simulador de prueba.
7. Probar compra sandbox de punta a punta (7.3): compra → webhook → `entitlements` → `summarize-articles` deja generar.
8. (Opcional, no bloqueante) Crear el producto anual en ASC y en Superwall si se quiere ofrecer esa opción desde el lanzamiento.
