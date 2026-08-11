## MODIFIED Requirements

### Requirement: Generación de una dirección de email y feed RSS únicos
El sistema SHALL, ante una solicitud de creación, generar un identificador único (UUID v4), asociar una dirección de email (`<id>@<dominio configurado>`) y un feed RSS correspondiente (`/functions/v1/feed/<id>`), y persistir un registro en `generated_feeds` con un label opcional.

La solicitud de creación SHALL autenticarse con el access token de la sesión activa del usuario. El backend SHALL rechazar con un error de autenticación cualquier solicitud cuyo token no corresponda a una sesión de usuario autenticada (incluyendo solicitudes hechas con una key pública/anónima en vez de una sesión real), sin crear ningún registro en ese caso.

#### Scenario: Creación exitosa con label
- **WHEN** se solicita crear un feed con label "Newsletter de Fulano"
- **THEN** el sistema devuelve un id nuevo, la dirección de email `<id>@<dominio>` y la URL del feed correspondiente

#### Scenario: Creación exitosa sin label
- **WHEN** se solicita crear un feed sin especificar label
- **THEN** el sistema genera el feed igual, usando un título por defecto para el canal RSS

#### Scenario: Solicitud sin sesión de usuario activa
- **WHEN** no hay una sesión de usuario activa en el dispositivo
- **THEN** el sistema no envía ninguna solicitud al backend de creación de feed, y falla con un error indicando que se requiere sesión activa

#### Scenario: Backend rechaza solicitudes sin sesión de usuario autenticada
- **WHEN** el backend de creación de feed recibe una solicitud cuyo token no corresponde a una sesión de usuario autenticada (ej. una key anónima/pública)
- **THEN** el backend responde con un error de autenticación y no crea ningún registro en `generated_feeds`
