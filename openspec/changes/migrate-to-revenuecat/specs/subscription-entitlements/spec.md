## RENAMED Requirements

- FROM: `### Requirement: Identificación del usuario ante Superwall`
- TO: `### Requirement: Identificación del usuario ante RevenueCat`

- FROM: `### Requirement: Consulta de entitlement local, sin llamar a Superwall en cada request`
- TO: `### Requirement: Consulta de entitlement local, sin llamar a RevenueCat en cada request`

## MODIFIED Requirements

### Requirement: Identificación del usuario ante RevenueCat
El sistema SHALL identificar a cada usuario ante el SDK de RevenueCat usando el mismo `user_id` de Supabase Auth, inmediatamente después de un login exitoso, y SHALL desvincularlo al cerrar sesión o al borrar la cuenta, de modo que el estado de suscripción de una cuenta no se arrastre a otra que inicie sesión después en el mismo dispositivo.

#### Scenario: Login exitoso identifica al usuario en RevenueCat
- **WHEN** el usuario completa el login (Google o Apple)
- **THEN** el sistema identifica la sesión de RevenueCat con el `user_id` de Supabase Auth de esa cuenta

#### Scenario: Cerrar sesión desvincula al usuario
- **WHEN** el usuario cierra sesión o elimina su cuenta
- **THEN** el sistema desvincula al usuario de RevenueCat y el estado de suscripción local deja de reflejar a la cuenta anterior

#### Scenario: El estado inicial de suscripción viene de la caché del SDK
- **WHEN** la app arranca con una sesión ya iniciada y sin red
- **THEN** el sistema determina si el usuario es suscriptor a partir del último estado conocido por el SDK, sin esperar una llamada de red

### Requirement: Sincronización de entitlements vía webhook
El sistema SHALL exponer un endpoint (`revenuecat-webhook`) que reciba los avisos de cambio de suscripción emitidos por RevenueCat, valide que el request trae el valor de autorización configurado (comparado en tiempo constante), y, ante cualquier evento de un usuario, consulte a la API de RevenueCat el estado vigente del entitlement `pro` de ese usuario y refleje ese resultado en la tabla `entitlements` (`user_id`, `is_active`, `updated_at`). El sistema NO SHALL deducir el estado a partir del tipo de evento recibido, para que el resultado no dependa del orden de llegada de los eventos. Un usuario con una prueba gratis vigente SHALL contarse como activo.

#### Scenario: Evento de un usuario con suscripción vigente
- **WHEN** RevenueCat envía un evento para un `user_id` cuyo entitlement `pro` está vigente en ese momento (suscripción de pago o prueba gratis)
- **THEN** el sistema marca `is_active = true` para ese `user_id` en `entitlements`

#### Scenario: Evento de un usuario sin acceso vigente
- **WHEN** RevenueCat envía un evento para un `user_id` cuyo entitlement `pro` ya no está vigente (expiración, reembolso o fin del periodo)
- **THEN** el sistema marca `is_active = false` para ese `user_id` en `entitlements`

#### Scenario: Cancelar la renovación no revoca el acceso
- **WHEN** RevenueCat envía un evento de cancelación de la renovación automática y el periodo ya pagado (o la prueba) todavía no terminó
- **THEN** el sistema mantiene `is_active = true` hasta que el entitlement deje de estar vigente

#### Scenario: Eventos que llegan desordenados no dejan un estado viejo
- **WHEN** llega un evento atrasado de una compra después de un evento de expiración, o viceversa
- **THEN** `entitlements` queda con el estado vigente que RevenueCat informa en ese momento, no con el que sugiere el evento atrasado

#### Scenario: Webhook sin la autorización correcta se rechaza
- **WHEN** llega un request a `revenuecat-webhook` cuya cabecera de autorización no coincide con el valor configurado
- **THEN** el sistema responde 401 sin consultar a RevenueCat ni modificar `entitlements`

#### Scenario: Usuario inexistente en este proyecto se ignora
- **WHEN** llega un evento para un `user_id` que no existe en `auth.users` del proyecto de Supabase que recibe el webhook (por ejemplo, una compra de sandbox de un usuario de `reevo-dev` que llega al webhook de `reevo`, o una cuenta ya borrada)
- **THEN** el sistema responde 200 sin crear ni modificar ninguna fila de `entitlements`

#### Scenario: Falla la consulta a RevenueCat
- **WHEN** la API de RevenueCat no responde o devuelve un error al consultar el estado de un usuario
- **THEN** el sistema responde con un error de servidor para que RevenueCat reintente el aviso, sin modificar `entitlements`

#### Scenario: Eventos con un identificador anónimo se ignoran
- **WHEN** llega un evento cuyo usuario es un identificador anónimo de RevenueCat (no un `user_id` de Supabase)
- **THEN** el sistema responde 200 sin modificar `entitlements`

### Requirement: Consulta de entitlement local, sin llamar a RevenueCat en cada request
El sistema SHALL determinar si un usuario tiene una suscripción activa consultando la tabla `entitlements` local, no llamando a la API de RevenueCat en el momento de la consulta.

#### Scenario: Usuario sin fila en entitlements se trata como sin suscripción
- **WHEN** se consulta el entitlement de un `user_id` que no tiene ninguna fila en `entitlements` (nunca tuvo suscripción)
- **THEN** el sistema lo trata como sin suscripción activa

## ADDED Requirements

### Requirement: Sincronización inmediata del entitlement tras comprar o restaurar
El sistema SHALL exponer un endpoint autenticado con la sesión del usuario (`sync-entitlement`) que consulte a RevenueCat el estado vigente del entitlement `pro` del usuario autenticado y lo refleje en `entitlements`, y el cliente SHALL invocarlo tras una compra o una restauración exitosas, antes de ejecutar la acción que el usuario pidió originalmente (por ejemplo, generar el resumen de un artículo). El endpoint SHALL operar solo sobre el usuario de la sesión, nunca sobre un `user_id` recibido en el request.

#### Scenario: Compra desde el paywall y acción posterior
- **WHEN** el usuario completa una compra desde el paywall para generar el resumen de un artículo
- **THEN** el cliente sincroniza el entitlement antes de pedir el resumen, y el backend no rechaza la solicitud por falta de suscripción

#### Scenario: Restauración exitosa sincroniza el entitlement
- **WHEN** el usuario restaura sus compras y RevenueCat reporta una suscripción vigente
- **THEN** el cliente sincroniza el entitlement y `entitlements` queda con `is_active = true`

#### Scenario: Request sin sesión
- **WHEN** llega un request a `sync-entitlement` sin un access token válido de usuario
- **THEN** el sistema lo rechaza sin consultar a RevenueCat ni modificar `entitlements`

#### Scenario: No se puede sincronizar otro usuario
- **WHEN** un usuario autenticado intenta sincronizar el entitlement indicando el `user_id` de otra cuenta
- **THEN** el sistema ignora ese valor y solo actualiza la fila del usuario de la sesión

#### Scenario: Falla la sincronización tras pagar
- **WHEN** el usuario completó la compra pero `sync-entitlement` falla (por ejemplo, sin red)
- **THEN** el cliente sigue mostrando al usuario como suscriptor, porque el estado local viene del SDK, y el webhook repara `entitlements` cuando llegue el aviso de RevenueCat

### Requirement: Dos entornos de servidor con un único proyecto de RevenueCat
El sistema SHALL recibir los avisos de un único proyecto de RevenueCat en los dos proyectos de Supabase (`reevo` y `reevo-dev`), cada uno con su propio webhook y secret, y cada función SHALL actuar solo sobre los usuarios que existen en su propio proyecto.

#### Scenario: Compra sandbox de un usuario de desarrollo
- **WHEN** un usuario de `reevo-dev` completa una compra de sandbox con una build de desarrollo
- **THEN** `entitlements` de `reevo-dev` se actualiza y `entitlements` de `reevo` no recibe ninguna fila para ese usuario

### Requirement: Compatibilidad temporal con el webhook de Superwall
El sistema SHALL mantener desplegado `superwall-webhook`, sin cambios de comportamiento, hasta que se cumpla el criterio de retiro documentado: la versión del cliente con RevenueCat está en `READY_FOR_DISTRIBUTION` en la App Store y ninguna versión del cliente con Superwall (1.9.x, 1.10.x) registra actividad en los últimos 30 días. El sistema NO SHALL eliminar `superwall-webhook` ni su secret antes de cumplirse ese criterio.

#### Scenario: Webhook de Superwall sigue disponible tras publicar el cliente nuevo
- **WHEN** se publica la versión del cliente con RevenueCat y todavía hay versiones anteriores con actividad reciente
- **THEN** `superwall-webhook` permanece desplegado y sigue procesando eventos como antes

#### Scenario: Retiro del webhook de Superwall
- **WHEN** se cumple el criterio de retiro
- **THEN** se elimina `superwall-webhook`, su configuración y su secret en un PR posterior e independiente
