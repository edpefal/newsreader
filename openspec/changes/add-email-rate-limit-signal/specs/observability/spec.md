## ADDED Requirements

### Requirement: Señal de límite de envíos del inicio de sesión con correo

El sistema SHALL reportar al servicio de monitoreo de errores un mensaje de nivel de advertencia cada vez que el envío, el reenvío o la verificación del código de acceso por correo falla porque se superó el límite de solicitudes. El mensaje SHALL identificar el paso: `login_email_rate_limited: send` (primer envío), `login_email_rate_limited: resend` (reenvío) o `login_email_rate_limited: verify` (verificación del código), de modo que cada paso se agrupe por separado y se pueda alertar sobre ellos. El mensaje SHALL NOT incluir el correo del usuario, el código ingresado ni ningún otro dato personal. Los pasos `send` y `resend` representan el tope global de correos del servicio de autenticación y de envío; `verify` representa el límite por origen al verificar y no indica un bloqueo global. Otros errores del inicio de sesión con correo NO SHALL generar este mensaje. El reporte SHALL respetar la separación de entornos existente, de modo que las pruebas en desarrollo no se mezclen con producción.

#### Scenario: Límite al pedir el código

- **WHEN** el primer envío del código falla por límite de solicitudes
- **THEN** el sistema reporta el mensaje `login_email_rate_limited: send` con nivel de advertencia

#### Scenario: Límite al reenviar el código

- **WHEN** un reenvío del código falla por límite de solicitudes
- **THEN** el sistema reporta el mensaje `login_email_rate_limited: resend` con nivel de advertencia

#### Scenario: Límite al verificar el código

- **WHEN** la verificación del código falla por límite de solicitudes
- **THEN** el sistema reporta el mensaje `login_email_rate_limited: verify` con nivel de advertencia

#### Scenario: Otros errores no generan la señal

- **WHEN** el inicio de sesión con correo falla por un código inválido, un correo inválido, un error de red o cualquier causa distinta del límite de solicitudes
- **THEN** el sistema no reporta ningún mensaje `login_email_rate_limited`

#### Scenario: El mensaje no lleva datos personales

- **WHEN** el sistema reporta un mensaje `login_email_rate_limited`
- **THEN** su contenido incluye únicamente el paso, sin el correo ni el código ingresado
