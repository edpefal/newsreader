## Purpose

Proporciona un correo de soporte con dominio de Reevo para contacto público sin exponer la dirección personal del responsable.

## ADDED Requirements

### Requirement: Dirección pública de soporte
El sistema SHALL aceptar correos enviados a `support@getreevo.co` y entregarlos al buzón privado configurado del responsable, sin publicar ese buzón de destino.

#### Scenario: Usuario contacta soporte
- **WHEN** un usuario envía un correo a `support@getreevo.co`
- **THEN** el mensaje llega al buzón privado configurado del responsable

### Requirement: Contacto legal y de soporte de marca
Las páginas públicas `/terms`, `/privacy` y `/support` SHALL mostrar `support@getreevo.co` como dirección de contacto y SHALL ofrecer un enlace `mailto` a esa dirección.

#### Scenario: Usuario abre una página pública
- **WHEN** un usuario visita `/terms`, `/privacy` o `/support`
- **THEN** ve `support@getreevo.co` y puede iniciar un correo dirigido a esa dirección
