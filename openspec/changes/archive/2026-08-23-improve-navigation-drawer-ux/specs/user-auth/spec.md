## ADDED Requirements

### Requirement: Identificación de la sesión activa en el NavigationDrawer
El sistema SHALL mostrar el email del usuario de la sesión activa en el `NavigationDrawer`, para que el usuario pueda identificar con qué cuenta está autenticado.

#### Scenario: Usuario abre el NavigationDrawer con sesión activa
- **WHEN** el usuario abre el `NavigationDrawer` con una sesión activa
- **THEN** el sistema muestra el email de esa sesión en el header del drawer
