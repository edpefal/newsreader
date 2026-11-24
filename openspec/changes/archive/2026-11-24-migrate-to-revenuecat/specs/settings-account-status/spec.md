## MODIFIED Requirements

### Requirement: Cuenta Free ofrece un botón para volverse Premium
El sistema SHALL mostrar, cuando la cuenta del usuario es Free, un botón que le permita iniciar el flujo de upgrade a Premium.

#### Scenario: Usuario Free ve el botón de upgrade
- **WHEN** el usuario no tiene una suscripción activa
- **THEN** la sección de estado de cuenta muestra "Free" junto con un botón para volverse Premium

#### Scenario: Usuario Free toca el botón de upgrade
- **WHEN** el usuario toca el botón de volverse Premium
- **THEN** el sistema muestra el paywall de suscripción de la app

#### Scenario: Usuario completa la compra desde Ajustes
- **WHEN** el usuario completa una compra desde el paywall mostrado desde Ajustes
- **THEN** la sección de estado de cuenta se actualiza para mostrar "Premium" sin que el usuario tenga que salir y volver a entrar a Ajustes

## ADDED Requirements

### Requirement: Restaurar compras y gestionar la suscripción desde Ajustes
El sistema SHALL mostrar en Ajustes, dentro de la sección de estado de cuenta, una acción "Restaurar compras" para cualquier usuario, y una acción "Gestionar suscripción" solo cuando el usuario tiene una suscripción activa. "Gestionar suscripción" SHALL abrir la página de suscripciones de Apple del usuario.

#### Scenario: Usuario Free ve Restaurar compras
- **WHEN** un usuario sin suscripción activa abre Ajustes
- **THEN** la sección de estado de cuenta muestra la acción "Restaurar compras" y no muestra "Gestionar suscripción"

#### Scenario: Usuario Premium ve Gestionar suscripción
- **WHEN** un usuario con suscripción activa abre Ajustes
- **THEN** la sección de estado de cuenta muestra "Gestionar suscripción" y "Restaurar compras"

#### Scenario: Restaurar compras encuentra una suscripción
- **WHEN** el usuario toca "Restaurar compras" y la tienda tiene una suscripción activa asociada a su Apple ID
- **THEN** el sistema actualiza el estado de la cuenta a Premium y confirma la restauración al usuario

#### Scenario: Restaurar compras no encuentra ninguna suscripción
- **WHEN** el usuario toca "Restaurar compras" y no existe ninguna suscripción activa asociada a su Apple ID
- **THEN** el sistema le informa que no se encontraron compras para restaurar y el estado de la cuenta no cambia
