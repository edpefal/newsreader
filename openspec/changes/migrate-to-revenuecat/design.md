## Context

Hoy las suscripciones pasan por Superwall: `SuperwallSubscriptionStatusProvider` (cuatro métodos: `isSubscribed`, `identify`, `reset`, `showPaywall`), `Superwall.configure` bloqueante en `main.dart`, un paywall remoto mostrado con `registerPlacement('daily_summary')`, y `superwall-webhook` que traduce tipos de evento a `entitlements.is_active`. La tabla `entitlements` y el gate de `summarize-article`/`generate-daily-summaries` son independientes del proveedor y no cambian. Motivación y alcance en `proposal.md`; el comportamiento exigido está en los specs.

Restricciones que dan forma al diseño:
- No hay suscriptores reales (en prod, una fila inactiva de pruebas): el corte puede ser limpio.
- `superwallkit_flutter` no soporta macOS; `purchases_flutter` sí, pero `purchases_ui_flutter` no. El paywall debe ser un widget propio para poder reutilizarse en el change posterior `add-macos-support`.
- Los features no se importan entre sí (CLAUDE.md), y tres features (Ajustes, resumen de artículo, lector) abren el paywall.
- Apple permite una sola URL de notificaciones del servidor por app.
- Android no tiene compras hoy (la llave de Superwall era un placeholder).
- Dos proyectos de Supabase (`reevo`, `reevo-dev`) y un solo proyecto de RevenueCat.

## Goals / Non-Goals

**Goals:**
- Mantener intacta la interfaz hacia el resto de la app (`isSubscribed`, `identify`, `reset`) y la tabla `entitlements`.
- Un paywall único que sirva a iOS, iPad y, después, Mac.
- Que `entitlements` converja siempre al estado real de RevenueCat, sin depender del orden de los eventos.
- Que comprar y usar el feature premium inmediatamente después funcione.

**Non-Goals:**
- Soporte de macOS (change posterior) ni de compras en Android.
- Migrar suscriptores existentes (no hay).
- Experimentos de precios o paywalls remotos.
- Eliminar `superwall-webhook` (queda para un PR posterior con criterio de retiro).

## Decisions

### D1. Se conserva `SubscriptionStatusProvider`; pierde `showPaywall` y gana las operaciones de compra
La interfaz queda con `isSubscribed`, `identify`, `reset` y las operaciones puras de compra: obtener ofertas, comprar un paquete y restaurar. `RevenueCatSubscriptionStatusProvider` es la única clase que importa `purchases_flutter` (regla de abstracciones). `isSubscribed` es un `bool` síncrono alimentado por `CustomerInfo`: el estado inicial sale de la caché del SDK (`getCustomerInfo`) y se actualiza con `addCustomerInfoUpdateListener`.
*Alternativa descartada:* hacer `isSubscribed` asíncrono. Habría obligado a tocar los tres consumidores (Ajustes, lector, `AiUsageRepositoryImpl`) sin ganar nada; la caché del SDK ya da un valor local instantáneo.

### D2. `PaywallLauncher` a nivel de app, para respetar "un feature no importa de otro"
`core/subscription/paywall_launcher.dart` declara `Future<bool> show(BuildContext context, {required String trigger})`. La implementación (`AppPaywallLauncher`), `PaywallScreen` y `PaywallCubit` viven en `lib/presentation/paywall/`, junto a `presentation/app` (elementos a nivel de app). Los features reciben el launcher por constructor y esperan un `bool` (`true` si quedó suscrito). Ahí también se emiten los eventos de PostHog del paywall.
La presentación depende del ancho: `< 840dp` ruta modal a pantalla completa, `≥ 840dp` diálogo centrado (`kExpandedWidthBreakpoint`). `PaywallScreen` no incluye `Scaffold` propio con `AppBar` cuando va en diálogo; en modal usa un cierre simple.
*Alternativas descartadas:* `features/paywall/` (los otros features tendrían que importarlo); la pantalla en `core/widgets/` (esa carpeta es para abstracciones de librerías de terceros); un paywall por feature (duplica lo más delicado).

### D3. El webhook consulta el estado, no interpreta eventos
`revenuecat-webhook` valida la cabecera `Authorization` (comparación en tiempo constante contra un secret), extrae el `app_user_id` del evento y consulta `GET /v1/subscribers/{id}` con la clave secreta de la API REST; si el entitlement `pro` está vigente (`expires_date` futuro o nulo, incluyendo `period_type = trial`) escribe `is_active = true`, si no, `false`. La lógica de "leer el estado y hacer upsert" se extrae a un módulo (`entitlement_state.ts`) que reutiliza `sync-entitlement`; como cada Edge Function se despliega como unidad autocontenida, se copia en ambas, igual que ya se hace con `entitlement.ts`.
Se ignoran con 200: identificadores anónimos de RevenueCat (`$RCAnonymousID:`), usuarios que no existen en `auth.users` del proyecto (necesario porque un único proyecto de RevenueCat envía eventos de usuarios de `reevo` y `reevo-dev` a ambos webhooks, y `entitlements.user_id` tiene FK a `auth.users`), y eventos sin `app_user_id`. Si la API de RevenueCat falla, se responde 500 para que RevenueCat reintente.
*Alternativa descartada:* un mapa tipo-de-evento → verdadero/falso como en `superwall-webhook`. Es el origen de los casos delicados del esquema anterior (cancelación que no revoca, reembolsos con precios negativos) y depende del orden de llegada.

### D4. `sync-entitlement` para cerrar la carrera post-compra
Sin esto, `cubit.generate()` corre justo después de comprar y `summarize-article` lee `entitlements` antes de que llegue el webhook: 403 `subscription_required` a alguien que acaba de pagar. `sync-entitlement` (JWT de Supabase requerido, `verify_jwt = true`) toma el `user_id` del token (nunca del body), consulta a RevenueCat y hace upsert. El cliente lo invoca (vía `CloudSyncClient`, la abstracción de Supabase) tras una compra o restauración exitosas y antes de ejecutar `onSubscribed`. Si falla (sin red), el flujo continúa: el SDK ya dice `isSubscribed = true` y el webhook repara `entitlements` luego.
*Alternativas descartadas:* reintento con espera en el cliente (UX de "cargando" dependiente del tiempo) y que `summarize-article` consulte a RevenueCat ante un 403 (acopla cada llamada de un usuario gratuito a un servicio externo).

### D5. Un proyecto de RevenueCat, dos webhooks, entitlement `pro`
Se conserva el nombre de entitlement `pro` que ya usa `annual-subscription-plan`. Los dos webhooks (a `reevo` y a `reevo-dev`) reciben sandbox y producción; el aislamiento lo da el `user_id`, distinto en cada proyecto de Supabase, más la verificación de existencia de D3. Secrets por proyecto: `REVENUECAT_WEBHOOK_AUTH` y `REVENUECAT_SECRET_API_KEY`. La llave pública (`appl_…`) va en `AppConfig` y no es un secreto.

### D6. Identidad: `logIn` tras el login, `logOut` al salir
`Purchases.configure` se llama sin `appUserID` y sin bloquear el arranque en red (a diferencia de `Superwall.configure`, que se esperaba por el event channel). `identify` hace `logIn(userId)`; `reset` hace `logOut()`. En la ventana entre `configure` y `logIn` el usuario es anónimo en RevenueCat: los eventos de ese identificador se ignoran en el servidor (D3). El orden en `main.dart` (configure → DI → identify con la sesión existente) se mantiene; solo se elimina la espera bloqueante.

### D7. Oferta de introducción y elegibilidad
La prueba de 7 días vive en App Store Connect, solo en el producto anual. El paywall decide si mostrarla con la elegibilidad que informa el SDK para ese producto; si no es elegible, muestra el precio completo sin mencionar prueba. Cuando hay prueba, el botón y el texto legal indican cuándo empieza el cobro.

### D8. Borrado de cuenta
`delete-account` llama `DELETE /v1/subscribers/{app_user_id}` de RevenueCat antes de borrar `auth.users`; un fallo se reporta a Sentry (sin PII) y no interrumpe el borrado. En el cliente, el diálogo de confirmación añade el aviso (solo si `isSubscribed`) con un botón que abre `https://apps.apple.com/account/subscriptions` mediante `ExternalLinkLauncher`.

### D9. Retiro de Superwall en dos tiempos
En este change el cliente deja de depender de Superwall por completo y `superwall-webhook` queda desplegado sin cambios. El archivado del campaign de Superwall y el cambio de la URL de notificaciones de Apple a RevenueCat son pasos manuales posteriores a que la versión nueva esté en `READY_FOR_DISTRIBUTION` (regla de CLAUDE.md sobre servidor y clientes ya publicados). Retirar `superwall-webhook` es un PR aparte cuando ninguna 1.9.x/1.10.x tenga actividad en 30 días.

### D10. Android
`AppConfig` expone la llave de RevenueCat por plataforma; en Android no hay llave y `RevenueCatSubscriptionStatusProvider` no configura el SDK y reporta `isSubscribed = false`. Así la app sigue compilando y el provider no tiene supuestos de plataforma: agregar Android (o macOS) es configuración y una llave.

## Risks / Trade-offs

- [Un usuario con un cliente 1.9/1.10 paga por Superwall después del corte] → riesgo remoto (cero compradores reales hasta hoy); `superwall-webhook` sigue vivo, y el campaign de Superwall se archiva solo cuando la versión nueva está pública; además `showPaywall` en esos clientes ejecuta la acción solo si `isSubscribed`.
- [Retraso del webhook tras una renovación o expiración] → el gate de IA del servidor puede ir un poco desfasado hasta que llegue el aviso (la expiración de un cliente nuevo se detecta con la notificación de Apple, que se mueve a RevenueCat tras la publicación); aceptable por el bajo volumen y mitigado por `sync-entitlement` en las compras.
- [Dos webhooks reciben eventos de todos los usuarios] → cada función ignora con 200 a quien no existe en su proyecto; hay un costo marginal de una consulta a la API por evento ajeno.
- [La API REST de RevenueCat falla o limita] → 500 para reintento; `entitlements` queda sin modificar y consistente.
- [La app se rechaza en App Review por el paywall propio] → texto de renovación, precios de la tienda, enlaces legales y "Restaurar compras" dentro del paywall y en Ajustes; verificado en sandbox y TestFlight antes de enviar.
- [Suscriptor sin fila en `entitlements` mientras el webhook aún no llega y no hubo `sync-entitlement`] → no ocurre tras compra o restauración; en una reinstalación el usuario restaura y se sincroniza.
- [El estado inicial de `isSubscribed` es `false` hasta cargar la caché del SDK] → se inicializa el provider antes del primer frame útil y se refresca por listener; Ajustes se reconstruye al cambiar el estado.

## Migration Plan

1. Configuración externa (usuario): proyecto de RevenueCat, entitlement `pro`, offering con ambos planes, credenciales de App Store Connect, oferta de 7 días en el anual, dos webhooks, y secrets en `reevo` y `reevo-dev`.
2. Desplegar `revenuecat-webhook`, `sync-entitlement` y `delete-account` a `reevo-dev` y probar con una build de desarrollo en sandbox; luego a `reevo`.
3. Publicar la build con RevenueCat por TestFlight (Codemagic) y probar compra, prueba gratis, restauración, expiración, borrado de cuenta y que el resumen funcione justo tras comprar.
4. Enviar a revisión. Cuando esté en `READY_FOR_DISTRIBUTION`: mover la URL de notificaciones de Apple a RevenueCat y archivar el campaign de Superwall.
5. PR posterior: retirar `superwall-webhook` y su secret cuando se cumpla el criterio de retiro.

*Rollback:* mientras `superwall-webhook` siga desplegado y el campaign de Superwall activo, las versiones anteriores siguen funcionando. Un fallo del cliente nuevo se corrige con una nueva versión; no hay migración de datos que revertir (la tabla `entitlements` no cambia).

## Open Questions

- ¿El mínimo de iOS del `Podfile` (14.0) cumple el de `purchases_flutter`? Se verifica al agregar la dependencia.
- Identificadores de los productos y del grupo de suscripción que conecta RevenueCat: se reutilizan los actuales de App Store Connect.
