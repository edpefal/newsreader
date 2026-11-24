## MODIFIED Requirements

### Requirement: El paywall ofrece ambos planes como opciones
El paywall de la app SHALL mostrar el plan anual como opción junto al mensual, de forma que el usuario pueda elegir entre ambos antes de comprar, cada uno con el precio formateado por la tienda para la región del usuario.

#### Scenario: Usuario ve ambas opciones en el paywall
- **WHEN** un usuario sin suscripción activa abre el paywall de Reevo Premium
- **THEN** ve tanto el plan mensual como el anual, con su precio correspondiente

## ADDED Requirements

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
