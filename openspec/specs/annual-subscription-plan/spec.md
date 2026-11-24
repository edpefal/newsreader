## Purpose

Ofrece un plan de suscripción anual de Reevo Premium como alternativa al mensual, otorgando el mismo acceso, para usuarios que prefieren pagar una vez al año a un mejor valor.

## Requirements

### Requirement: Producto anual disponible en App Store Connect
El sistema SHALL tener un producto de suscripción anual configurado en App Store Connect, dentro del mismo subscription group que el producto mensual, en estado apto para venta (`READY_TO_SUBMIT` o superior).

#### Scenario: Producto anual listo para la venta
- **WHEN** se consulta el estado del producto anual en App Store Connect
- **THEN** el producto no está en `MISSING_METADATA` y tiene precio y disponibilidad por territorio configurados

### Requirement: El plan anual otorga el mismo entitlement que el mensual
El sistema SHALL vincular el producto anual al mismo entitlement (`pro`) que usa el producto mensual, de forma que un usuario con cualquiera de los dos planes activos tenga acceso idéntico a las funciones premium.

#### Scenario: Usuario con plan anual accede a resúmenes diarios
- **WHEN** un usuario con el plan anual activo intenta generar un resumen diario
- **THEN** el sistema le otorga acceso igual que a un usuario con el plan mensual activo

### Requirement: El paywall ofrece ambos planes como opciones
El paywall de la app SHALL mostrar el plan anual como opción junto al mensual, de forma que el usuario pueda elegir entre ambos antes de comprar, cada uno con el precio formateado por la tienda para la región del usuario.

#### Scenario: Usuario ve ambas opciones en el paywall
- **WHEN** un usuario sin suscripción activa abre el paywall de Reevo Premium
- **THEN** ve tanto el plan mensual como el anual, con su precio correspondiente

### Requirement: Prueba gratis de 7 días en el plan anual
El sistema SHALL ofrecer una oferta de introducción de 7 días gratis únicamente en el plan anual, configurada en App Store Connect. El plan mensual NO SHALL tener oferta de introducción. La prueba gratis SHALL otorgar el mismo acceso que una suscripción de pago durante su vigencia.

#### Scenario: Usuario elegible ve la prueba en el plan anual
- **WHEN** un usuario elegible para la oferta de introducción abre el paywall
- **THEN** el plan anual indica los 7 días gratis y a partir de cuándo se cobra, y el plan mensual no muestra ninguna prueba

#### Scenario: Usuario no elegible no ve la prueba
- **WHEN** un usuario que ya usó la oferta de introducción de ese grupo de suscripción abre el paywall
- **THEN** el paywall muestra el plan anual a precio completo, sin mencionar una prueba gratis

#### Scenario: Usuario en prueba accede a las funciones premium
- **WHEN** un usuario con la prueba gratis vigente genera un resumen de artículo
- **THEN** el sistema le otorga el mismo acceso y presupuesto diario que a un suscriptor de pago

#### Scenario: Cancelar durante la prueba conserva el acceso hasta que termine
- **WHEN** el usuario cancela la renovación durante los 7 días de prueba
- **THEN** conserva el acceso hasta que la prueba termine y luego se revoca, sin que se le cobre
