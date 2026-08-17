## Purpose

Mantener, del lado del servidor, el estado de suscripción de cada usuario sincronizado desde Superwall, para que otras capabilities (como `daily-summaries`) puedan verificar de forma confiable y local si un usuario tiene acceso pago activo, sin depender de una llamada en vivo a Superwall en cada request.

## ADDED Requirements

### Requirement: Identificación del usuario ante Superwall
El sistema SHALL identificar a cada usuario ante el SDK de Superwall usando el mismo `user_id` de Supabase Auth, inmediatamente después de un login exitoso.

#### Scenario: Login exitoso identifica al usuario en Superwall
- **WHEN** el usuario completa el login (Google o Apple)
- **THEN** el sistema identifica la sesión de Superwall con el `user_id` de Supabase Auth de esa cuenta

### Requirement: Sincronización de entitlements vía webhook
El sistema SHALL exponer un endpoint (`superwall-webhook`) que reciba los eventos de cambio de estado de suscripción emitidos por Superwall (alta, renovación, cancelación, expiración, reembolso), valide la firma de cada request usando el signing secret configurado, y actualice una tabla `entitlements` (`user_id`, `is_active`, `updated_at`) reflejando el estado resultante para ese usuario.

#### Scenario: Webhook de suscripción activada actualiza el entitlement
- **WHEN** Superwall envía un evento de suscripción activada (alta o renovación) para un `user_id`
- **THEN** el sistema marca `is_active = true` para ese `user_id` en `entitlements`

#### Scenario: Webhook de cancelación o expiración actualiza el entitlement
- **WHEN** Superwall envía un evento de cancelación, expiración o reembolso para un `user_id`
- **THEN** el sistema marca `is_active = false` para ese `user_id` en `entitlements`

#### Scenario: Webhook con firma inválida se rechaza
- **WHEN** llega un request a `superwall-webhook` cuya firma no coincide con el signing secret configurado
- **THEN** el sistema rechaza el request sin modificar `entitlements`

### Requirement: Consulta de entitlement local, sin llamar a Superwall en cada request
El sistema SHALL determinar si un usuario tiene una suscripción activa consultando la tabla `entitlements` local, no llamando a la API de Superwall en el momento de la consulta.

#### Scenario: Usuario sin fila en entitlements se trata como sin suscripción
- **WHEN** se consulta el entitlement de un `user_id` que no tiene ninguna fila en `entitlements` (nunca tuvo suscripción)
- **THEN** el sistema lo trata como sin suscripción activa
