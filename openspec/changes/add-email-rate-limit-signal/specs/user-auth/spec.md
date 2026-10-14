## ADDED Requirements

### Requirement: Alternativa ante el límite de envíos de códigos

Cuando el envío o reenvío del código de acceso por correo, o su verificación, falla porque se superó el límite de solicitudes, el sistema SHALL mostrar un mensaje localizado que, además de indicar que hay demasiadas solicitudes, ofrezca la salida: intentar más tarde o iniciar sesión con Google o Apple. El mensaje SHALL mostrarse dentro de la pantalla de login, sin salir del flujo, y el usuario SHALL poder volver a la vista inicial con las acciones de volver ya existentes para elegir Google o Apple. El mensaje SHALL estar disponible en inglés, español y francés.

#### Scenario: Límite al pedir el código

- **WHEN** el usuario pide el código con su correo y el servicio rechaza el envío por límite de solicitudes
- **THEN** el sistema muestra en el paso del correo el mensaje que sugiere intentar más tarde o entrar con Google o Apple
- **AND** el usuario permanece en la pantalla de login

#### Scenario: Límite al reenviar el código

- **WHEN** el usuario pide reenviar el código y el servicio rechaza el envío por límite de solicitudes
- **THEN** el sistema muestra en el paso del código el mismo mensaje con la alternativa de Google o Apple

#### Scenario: Volver y elegir otro método

- **WHEN** el usuario ve el mensaje de límite en cualquier paso del flujo de correo y vuelve atrás hasta la vista inicial
- **THEN** el sistema muestra de nuevo los botones de Google y Apple, que siguen funcionando con normalidad

#### Scenario: Mensaje en cada idioma

- **WHEN** el idioma de la app es inglés, español o francés
- **THEN** el mensaje de límite de solicitudes se muestra en ese idioma con la misma sugerencia de alternativa
