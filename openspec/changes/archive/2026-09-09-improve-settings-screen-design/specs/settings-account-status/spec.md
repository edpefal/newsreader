## MODIFIED Requirements

### Requirement: Sección de estado de cuenta visible primero en Ajustes
El sistema SHALL mostrar, como la primera sección de la pantalla de Ajustes, el estado de la cuenta del usuario (Free o Premium) junto con el email de la cuenta. Las acciones de cuenta (exportar datos, eliminar cuenta, cerrar sesión) SHALL mostrarse en una sección propia distinta, separada de la de email/plan por al menos otra sección intermedia.

#### Scenario: Usuario abre Ajustes
- **WHEN** el usuario abre la pantalla de Ajustes
- **THEN** la primera sección visible muestra el email de la cuenta autenticada y si es Free o Premium, antes de cualquier otra sección (ej. tema)

#### Scenario: Acciones de cuenta en su propia sección
- **WHEN** el usuario abre la pantalla de Ajustes
- **THEN** las acciones de exportar datos, eliminar cuenta y cerrar sesión aparecen agrupadas bajo su propio título de sección, separado del título de la sección de email/plan
