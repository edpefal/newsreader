## ADDED Requirements

### Requirement: Compras en macOS
El sistema SHALL ofrecer en macOS las mismas compras que en iOS: el paywall presenta los planes mensual y anual con los precios que devuelve la tienda, permite comprarlos y restaurar compras, y enlaza a la gestión de suscripciones de Apple. Las compras hechas en iOS y en macOS SHALL compartir el mismo entitlement `pro`, de modo que una suscripción activa en una plataforma desbloquea la otra con la misma cuenta.

#### Scenario: Paywall en macOS
- **WHEN** un usuario sin suscripción abre el paywall en la app de Mac
- **THEN** ve los planes mensual y anual con los precios de la tienda y un botón para comprar el plan seleccionado

#### Scenario: Compra en macOS
- **WHEN** el usuario compra un plan en la app de Mac y la compra se completa
- **THEN** el sistema refleja el entitlement en el servidor y desbloquea las funciones de suscripción, igual que en iOS

#### Scenario: Restaurar compras en macOS
- **WHEN** un usuario que ya compró en iOS toca "Restaurar compras" en la app de Mac
- **THEN** el sistema recupera su suscripción y la marca como activa

#### Scenario: Suscripción comprada en iOS
- **WHEN** un usuario con suscripción activa comprada en iOS abre la app de Mac con la misma cuenta
- **THEN** el sistema lo trata como suscriptor sin mostrarle el paywall como obstáculo

#### Scenario: Paywall en una ventana angosta
- **WHEN** el usuario abre el paywall con la ventana de Mac por debajo de 840dp de ancho
- **THEN** el sistema lo presenta como pantalla modal, igual que en iOS por debajo de ese ancho
