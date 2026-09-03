## ADDED Requirements

### Requirement: Límite de creación de feeds por hora es por usuario
El sistema SHALL contar, para el límite horario de creación de feeds generados, únicamente los feeds creados por el mismo usuario autenticado que hace la solicitud, no el total de feeds creados por todos los usuarios. Al alcanzar ese límite, el sistema SHALL rechazar nuevas solicitudes de ese usuario sin afectar la capacidad de otros usuarios de crear sus propios feeds.

#### Scenario: Un usuario alcanza su propio límite horario
- **WHEN** un usuario ya creó el máximo de feeds permitidos por hora
- **THEN** el sistema rechaza una nueva solicitud de creación de ese mismo usuario con un error de límite alcanzado

#### Scenario: El límite de un usuario no afecta a otros usuarios
- **WHEN** un usuario ya alcanzó su límite horario de creación de feeds
- **THEN** otro usuario que todavía no alcanzó su propio límite puede crear un feed normalmente, sin verse bloqueado por el consumo del primero
