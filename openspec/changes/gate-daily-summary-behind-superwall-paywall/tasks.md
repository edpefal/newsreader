## 1. Base de datos

- [ ] 1.1 Nueva migración: tabla `entitlements` (`user_id uuid references auth.users`, `is_active boolean not null default false`, `updated_at timestamptz not null default now()`), con RLS habilitado.
- [ ] 1.2 Policy `entitlements_select_own`: el usuario puede `SELECT` solo su propia fila (`user_id = auth.uid()`).
- [ ] 1.3 Sin policy de `INSERT`/`UPDATE` para roles no privilegiados — solo `service_role` (usado por el webhook) puede escribir.

## 2. Edge Function: superwall-webhook

- [ ] 2.1 Verificar contra la documentación vigente de Superwall (superwall.com/docs) la forma real del payload y los nombres de eventos de suscripción antes de implementar — no asumir lo descripto en design.md al pie de la letra.
- [ ] 2.2 Crear `supabase/functions/superwall-webhook/index.ts`: valida la firma del request con `SUPERWALL_WEBHOOK_SECRET`; si es inválida, responde 401 sin tocar `entitlements`.
- [ ] 2.3 Parsear el evento y hacer upsert en `entitlements` (`is_active = true` para alta/renovación; `is_active = false` para cancelación/expiración/reembolso), usando `service_role`.
- [ ] 2.4 Configurar en el dashboard de Superwall la URL del webhook apuntando a esta función, y copiar el signing secret al secret `SUPERWALL_WEBHOOK_SECRET` de Supabase.

## 3. Backend: chequeo de entitlement en summarize-articles

- [ ] 3.1 Después de validar la sesión (`require-authenticated-session-for-summary-and-email-feed`), consultar `entitlements` para el `user_id` obtenido.
- [ ] 3.2 Si no hay fila o `is_active = false`, responder con un error de suscripción requerida (403) sin invocar a Gemini.

## 4. Cliente: SDK de Superwall

- [ ] 4.1 Agregar la dependencia del SDK de Superwall a `pubspec.yaml`.
- [ ] 4.2 `lib/core/subscription/subscription_status_provider.dart`: abstracción (`bool get isSubscribed` o similar, más el método para mostrar el paywall).
- [ ] 4.3 `lib/core/subscription/superwall_subscription_status_provider.dart`: implementación concreta con el SDK de Superwall.
- [ ] 4.4 Registrar la nueva abstracción en `lib/core/di/injection.dart`.
- [ ] 4.5 Tras un login exitoso, identificar al usuario en Superwall con su `user_id` de Supabase Auth.

## 5. Cliente: gate del botón de generar resumen

- [ ] 5.1 En `SummariesScreen`/`SummariesCubit`: antes de disparar `generateTodaySummary()`, chequear `SubscriptionStatusProvider.isSubscribed`; si es `false`, mostrar el paywall de Superwall en vez de generar.
- [ ] 5.2 Si el usuario completa la compra desde el paywall, disparar la generación automáticamente a continuación (sin que tenga que tocar el botón una segunda vez).

## 6. Tests

- [ ] 6.1 Unit test: `summarize-articles` (o su lógica de entitlement extraída a una función testeable) rechaza sin `is_active = true`.
- [ ] 6.2 Widget test: `SummariesScreen` muestra el paywall en vez de generar cuando no hay suscripción activa.
- [ ] 6.3 Widget test: `SummariesScreen` dispara la generación normalmente cuando hay suscripción activa.

## 7. Verificación

- [ ] 7.1 Correr `flutter analyze` sin warnings.
- [ ] 7.2 Correr `flutter test` y confirmar que toda la suite pasa.
- [ ] 7.3 Probar de punta a punta contra el proyecto Supabase de dev (no prod): pagar con una compra sandbox, confirmar que el webhook actualiza `entitlements`, y que recién ahí `summarize-articles` deja generar.
