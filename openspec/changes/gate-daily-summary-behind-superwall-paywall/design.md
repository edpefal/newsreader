## Context

Depende de `require-authenticated-session-for-summary-and-email-feed`: `summarize-articles` necesita conocer con confianza el `user_id` autenticado (vía `userClient.auth.getUser(token)`) antes de poder chequear su entitlement — sin esa base, cualquier chequeo de suscripción sería sobre una identidad no verificada. `core/auth/auth_client.dart` ya establece el patrón de abstracción para servicios de terceros (interfaz en `core/`, implementación concreta con el SDK real) que se sigue acá para Superwall. Ver proposal.md - Why.

## Goals / Non-Goals

**Goals:**
- El backend es la fuente de verdad de si un usuario puede generar un resumen — el paywall de la UI es una mejora de experiencia, no el único candado.
- `summarize-articles` chequea el entitlement contra una tabla local, sin latencia ni dependencia de la disponibilidad de Superwall en el momento de generar.

**Non-Goals:**
- No se paywallea `create-feed` (email-to-RSS) ni ninguna otra feature — solo el resumen diario.
- No se implementa lógica de trial/free-tier limitado (ej. "3 resúmenes gratis") — es binario: activo o no, según lo que Superwall reporte.
- No se define en este change el copy/diseño visual del paywall en sí — eso lo arma Superwall desde su dashboard (paywall remoto), no es código de la app.
- Los nombres exactos de los eventos y la forma exacta del payload de los webhooks de Superwall se verifican contra su documentación vigente al implementar (`superwall.com/docs`), no se fijan de antemano en este documento.

## Decisions

- **Nueva capability `subscription-entitlements`, no una extensión suelta dentro de `daily-summaries`**: el concepto de "¿este usuario tiene una suscripción activa?" es reusable — si en el futuro se paywallea alguna otra feature, ya existe la tabla y el webhook, solo hay que consultarlos. `daily-summaries` la referencia como dependencia en vez de duplicar el concepto.
- **Gate de UI con el estado local del SDK de Superwall, gate de backend con la tabla `entitlements`**: son dos chequeos con propósitos distintos. El de UI prioriza velocidad y funcionar offline (el SDK de Superwall ya mantiene su propio estado sincronizado con StoreKit/Play Billing); el de backend prioriza ser la fuente de verdad difícil de bypassear. No hace falta que sean la misma consulta.
- **`core/subscription/subscription_status_provider.dart`** (abstracción) **+ `SuperwallSubscriptionStatusProvider`** (implementación): sigue la regla de abstracciones del proyecto (ninguna librería de terceros se importa directo en `domain/`/`presentation/`), mismo patrón que `AuthClient`/`SupabaseAuthClient`.
- **Verificación de firma del webhook con el signing secret de Superwall** (secret de la Edge Function, `SUPERWALL_WEBHOOK_SECRET`), antes de tocar `entitlements` — sin esto, cualquiera podría pegarle al endpoint y activarse una suscripción gratis.
- **`entitlements` con RLS**: los usuarios pueden `SELECT` únicamente su propia fila (`user_id = auth.uid()`); solo el `service_role` (usado por `superwall-webhook`) puede escribir. `summarize-articles` lee con el cliente scoped al usuario (mismo `userClient` que ya usa para `getUser`), apoyándose en esa policy en vez de necesitar `service_role` para leer.
- **Ausencia de fila en `entitlements` = sin suscripción**, no un caso especial a manejar — evita tener que "sembrar" una fila en `false` para cada usuario nuevo.

## Risks / Trade-offs

- [Desfasaje entre el estado local del SDK de Superwall (usado para el gate de UI) y la tabla `entitlements` (usada por el backend) en la ventana entre que el usuario paga y el webhook llega] → Mitigación: el backend sigue siendo la fuente de verdad — en el peor caso, el usuario ve el botón habilitado un instante antes de que el webhook actualice la tabla, y el backend responde "se requiere suscripción" con un mensaje claro para reintentar en unos segundos, no un error confuso.
- [El payload/nombres de eventos reales de Superwall pueden diferir de lo asumido acá] → Mitigación: se verifica contra la documentación vigente al implementar (tasks.md lo marca explícitamente), sin bloquear el resto del diseño (la tabla `entitlements` y el chequeo en `summarize-articles` no dependen del detalle exacto del payload).
