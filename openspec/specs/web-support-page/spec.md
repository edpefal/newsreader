## Purpose

Da a Reevo una página pública de soporte/contacto, accesible por URL estable, para satisfacer el campo obligatorio "Support URL" de la ficha de App Store Connect y darle al usuario un canal real para reportar problemas.

## Requirements

### Requirement: Página pública de soporte
El sistema SHALL exponer una página pública en `/support` con un método de contacto real (email o formulario) para que el usuario reporte problemas, accesible sin autenticación.

#### Scenario: Acceso directo a soporte
- **WHEN** cualquier usuario visita `/support` en el dominio de Reevo, sin sesión iniciada
- **THEN** el sistema responde con status 200 y muestra un método de contacto funcional

### Requirement: URL estable apta para la ficha de App Store Connect
La URL de `/support` SHALL permanecer estable una vez publicada, de forma que el Support URL cargado en App Store Connect siga resolviendo al contenido correcto.

#### Scenario: Support URL cargado en App Store Connect sigue funcionando
- **WHEN** un revisor de Apple o un usuario final abre el Support URL publicado en la ficha de App Store Connect
- **THEN** la URL resuelve sin error 404 y muestra la página de soporte vigente
