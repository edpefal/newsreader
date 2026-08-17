## Purpose

Da a Reevo páginas públicas de Términos de Servicio y Política de Privacidad, accesibles por URL estable, que la app y el paywall pueden referenciar desde cualquier plataforma.

## ADDED Requirements

### Requirement: Página pública de Términos de Servicio
El sistema SHALL exponer una página pública en `/terms` con el texto de Términos de Servicio de Reevo, accesible sin autenticación.

#### Scenario: Acceso directo a Términos
- **WHEN** cualquier usuario visita `/terms` en el dominio de Reevo, sin sesión iniciada
- **THEN** el sistema responde con status 200 y el contenido completo de los Términos de Servicio

### Requirement: Página pública de Política de Privacidad
El sistema SHALL exponer una página pública en `/privacy` con el texto de Política de Privacidad de Reevo, accesible sin autenticación.

#### Scenario: Acceso directo a Privacidad
- **WHEN** cualquier usuario visita `/privacy` en el dominio de Reevo, sin sesión iniciada
- **THEN** el sistema responde con status 200 y el contenido completo de la Política de Privacidad

### Requirement: URLs estables aptas para revisión de Apple
Las URLs de `/terms` y `/privacy` SHALL permanecer estables una vez publicadas, de forma que enlaces guardados en el paywall de Superwall y en la ficha de la app en App Store Connect sigan resolviendo al contenido correcto.

#### Scenario: Link guardado en el paywall sigue funcionando
- **WHEN** un revisor de Apple o un usuario final abre el link de Términos/Privacidad guardado en el paywall
- **THEN** la URL resuelve sin error 404 y muestra el contenido legal vigente
