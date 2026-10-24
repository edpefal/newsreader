## ADDED Requirements

### Requirement: Solo un usuario con sesión puede consumir el límite diario

El sistema SHALL permitir invocar el chequeo e incremento del consumo diario de resúmenes únicamente a un usuario con sesión iniciada. Una invocación sin sesión SHALL ser rechazada por el servidor por falta de permiso, sin leer ni modificar ningún contador de uso. Este control SHALL aplicarse con los permisos de la propia función y no depender de que su lógica interna falle sin un usuario autenticado. El resumen de un artículo por parte de un usuario con sesión SHALL seguir funcionando y consumiendo su límite como hasta ahora.

#### Scenario: Invocación sin sesión

- **WHEN** alguien invoca el chequeo del consumo diario con la clave pública de la app y sin sesión de usuario
- **THEN** el servidor rechaza la invocación por falta de permiso y no modifica ningún contador de uso

#### Scenario: Usuario con sesión resume un artículo

- **WHEN** un usuario con sesión pide el resumen de un artículo y aún le queda cupo
- **THEN** el chequeo se ejecuta con su sesión, registra el consumo y el resumen se genera con normalidad

#### Scenario: Los permisos coinciden en desarrollo y producción

- **WHEN** se consultan los permisos de ejecución de la función en `reevo-dev` y en `reevo`
- **THEN** en ambos el rol anónimo no puede ejecutarla y los usuarios con sesión sí
