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
El paywall publicado SHALL mostrar el plan anual como opción junto al mensual, de forma que el usuario pueda elegir entre ambos antes de comprar.

#### Scenario: Usuario ve ambas opciones en el paywall
- **WHEN** un usuario sin suscripción activa abre el paywall de Reevo Premium
- **THEN** ve tanto el plan mensual como el anual, con su precio correspondiente
