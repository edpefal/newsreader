## Purpose

Darle al usuario un lugar claro y siempre disponible en Ajustes para conocer si su cuenta es Free o Premium, y un punto de entrada directo para volverse Premium sin depender de toparse con un límite de uso.

## ADDED Requirements

### Requirement: Sección de estado de cuenta visible primero en Ajustes
El sistema SHALL mostrar, como la primera sección de la pantalla de Ajustes, el estado de la cuenta del usuario (Free o Premium), unificada en la misma sección que el email de la cuenta y las acciones de cuenta (exportar datos, eliminar cuenta, cerrar sesión) — no como secciones separadas.

#### Scenario: Usuario abre Ajustes
- **WHEN** el usuario abre la pantalla de Ajustes
- **THEN** la primera sección visible muestra el email de la cuenta autenticada y si es Free o Premium, antes de cualquier otra sección (ej. tema)

### Requirement: Cuenta Premium no muestra invitación a suscribirse
El sistema SHALL ocultar cualquier botón o invitación a suscribirse cuando la cuenta del usuario ya es Premium.

#### Scenario: Usuario Premium ve su estado sin botón de upgrade
- **WHEN** el usuario tiene una suscripción activa
- **THEN** la sección de estado de cuenta muestra "Premium" y no muestra ningún botón para suscribirse

### Requirement: Cuenta Free ofrece un botón para volverse Premium
El sistema SHALL mostrar, cuando la cuenta del usuario es Free, un botón que le permita iniciar el flujo de upgrade a Premium.

#### Scenario: Usuario Free ve el botón de upgrade
- **WHEN** el usuario no tiene una suscripción activa
- **THEN** la sección de estado de cuenta muestra "Free" junto con un botón para volverse Premium

#### Scenario: Usuario Free toca el botón de upgrade
- **WHEN** el usuario toca el botón de volverse Premium
- **THEN** el sistema muestra el paywall remoto de suscripción

#### Scenario: Usuario completa la compra desde Ajustes
- **WHEN** el usuario completa una compra desde el paywall mostrado desde Ajustes
- **THEN** la sección de estado de cuenta se actualiza para mostrar "Premium" sin que el usuario tenga que salir y volver a entrar a Ajustes

### Requirement: Sección de cuenta muestra el email de la cuenta autenticada
El sistema SHALL mostrar, en la sección única de cuenta de Ajustes, el email de la cuenta actualmente autenticada.

#### Scenario: Usuario autenticado ve su email en Ajustes
- **WHEN** el usuario abre la pantalla de Ajustes con una sesión activa
- **THEN** la sección de cuenta muestra el email de la cuenta autenticada
