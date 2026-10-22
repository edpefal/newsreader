## Purpose

Permite que la app reporte errores no manejados y errores internamente capturados a un proveedor de observabilidad externo, para poder diagnosticar fallas en producción sin depender de que el usuario las reporte manualmente.
## Requirements
### Requirement: Captura de excepciones no manejadas
El sistema SHALL reportar al proveedor de observabilidad toda excepción no manejada que ocurra durante la ejecución de la app (tanto errores del framework de UI como errores asíncronos fuera de él), sin interrumpir el comportamiento de crash/recuperación que la plataforma ya tiene.

#### Scenario: Excepción no manejada durante el build de un widget
- **WHEN** ocurre una excepción no capturada mientras se construye o actualiza la interfaz
- **THEN** el proveedor de observabilidad recibe un reporte con la excepción y su stacktrace

#### Scenario: Excepción no manejada en código asíncrono
- **WHEN** ocurre una excepción no capturada dentro de una operación asíncrona (por ejemplo, una llamada de red disparada fuera del árbol de widgets)
- **THEN** el proveedor de observabilidad recibe un reporte con la excepción y su stacktrace

### Requirement: Reporte de errores capturados internamente
Cuando el sistema captura una excepción para manejarla (por ejemplo, para traducirla a un error genérico visible al usuario, o para descartarla porque no debe interrumpir el flujo principal), el sistema SHALL reportarla al proveedor de observabilidad antes de continuar con su manejo habitual, sin cambiar el comportamiento visible para el usuario.

#### Scenario: Error de red al sincronizar que ya se maneja como error genérico
- **WHEN** falla una operación de red que el sistema captura para mostrarle al usuario un mensaje de error genérico
- **THEN** el proveedor de observabilidad recibe un reporte con el error técnico real, y el usuario sigue viendo únicamente el mensaje genérico esperado

#### Scenario: Error en una operación best-effort que no debe interrumpir el flujo principal
- **WHEN** falla una operación secundaria que el sistema ya ignora intencionalmente para no interrumpir la acción principal del usuario
- **THEN** el proveedor de observabilidad recibe un reporte del error, y la acción principal del usuario se completa igual que antes

### Requirement: Asociación de reportes con el usuario activo
El sistema SHALL asociar los reportes de errores con el identificador del usuario con sesión activa cuando exista una, y SHALL dejar de asociarlos a ese usuario cuando la sesión termine, sin incluir información de identificación personal (como el email) en el reporte.

#### Scenario: Error mientras hay una sesión activa
- **WHEN** ocurre un error mientras el usuario tiene una sesión iniciada
- **THEN** el reporte queda asociado al identificador de ese usuario, sin incluir su email

#### Scenario: Error tras cerrar sesión
- **WHEN** el usuario cierra sesión o elimina su cuenta y luego ocurre un error
- **THEN** el reporte ya no se asocia al usuario anterior

### Requirement: Separación de entornos de desarrollo y producción
El sistema SHALL distinguir los reportes generados en un build de desarrollo de los generados en un build de producción, de forma que los errores de desarrollo local no se mezclen con los de usuarios reales.

#### Scenario: Error durante desarrollo local
- **WHEN** ocurre un error corriendo la app en modo desarrollo (`APP_ENV=dev` o equivalente)
- **THEN** el reporte queda identificado como proveniente del entorno de desarrollo, separado de los reportes de producción
</content>
</invoke>

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

