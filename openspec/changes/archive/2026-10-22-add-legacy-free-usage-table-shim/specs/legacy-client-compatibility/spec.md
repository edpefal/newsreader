## Purpose

Registra las obligaciones temporales del servidor hacia versiones de la app ya publicadas que todavía dependen de recursos que el cliente actual dejó de usar, para que retirar un recurso no rompa a quien aún no actualizó, y fija cuándo se puede retirar cada compatibilidad.

## ADDED Requirements

### Requirement: El servidor conserva la tabla de cupo gratis semanal para clientes 1.8.x hasta su retiro
Mientras existan usuarios activos en la versión `1.8.x` de la app, el sistema SHALL mantener en el servidor una tabla `daily_summary_free_usage` con las columnas `user_id`, `week_start`, `used` y `updated_at`, de modo que la consulta de solo lectura que hace ese cliente en cada sincronización se resuelva sin error. La tabla SHALL permanecer sin filas, SHALL estar protegida para que cada usuario solo pueda leer las suyas, y SHALL rechazar cualquier escritura de los clientes. El sistema NO SHALL recrear las funciones del servidor que escribían en esa tabla.

Esta compatibilidad SHALL limitarse a que la sincronización y el inicio de sesión de la `1.8.x` completen. La generación manual del resumen diario en esos clientes no queda soportada y SHALL seguir sin funcionar, porque ese flujo ya no existe en el servidor.

#### Scenario: Un cliente 1.8.x sincroniza sin error
- **WHEN** un cliente `1.8.x` con sesión iniciada ejecuta su sincronización completa
- **THEN** la consulta a `daily_summary_free_usage` devuelve cero filas sin error, y la sincronización termina y deja actualizado su cursor

#### Scenario: Un usuario nuevo inicia sesión en un cliente 1.8.x
- **WHEN** un usuario inicia sesión por primera vez desde un cliente `1.8.x`
- **THEN** la sincronización que se dispara al iniciar sesión completa y el Inbox deja de mostrar el indicador de carga

#### Scenario: La tabla no acepta escrituras de los clientes
- **WHEN** un cliente autenticado intenta insertar, actualizar o borrar una fila de `daily_summary_free_usage`
- **THEN** el servidor rechaza la operación y la tabla sigue sin filas

#### Scenario: Cada usuario solo lee sus filas
- **WHEN** un usuario autenticado consulta `daily_summary_free_usage`
- **THEN** solo podría ver filas cuyo `user_id` sea el suyo (hoy ninguna, porque la tabla está vacía)

#### Scenario: La generación manual de resumen sigue sin funcionar en 1.8.x
- **WHEN** un usuario de la `1.8.x` intenta generar a mano un resumen diario
- **THEN** la acción falla porque el flujo ya no existe en el servidor, sin que eso afecte a la sincronización ni al inicio de sesión

#### Scenario: El cliente actual no depende de la tabla
- **WHEN** un cliente `1.9.0` o posterior sincroniza
- **THEN** no consulta `daily_summary_free_usage`, de modo que la existencia o ausencia de la tabla no cambia su comportamiento

### Requirement: La tabla de compatibilidad se retira cuando ya no hay clientes 1.8.x activos
El sistema SHALL eliminar la tabla `daily_summary_free_usage` cuando se cumplan ambas condiciones: ningún usuario con sesión iniciada ha usado la versión `1.8.x` durante 14 días consecutivos según la analítica de producto, y el seguimiento de errores no registra eventos nuevos de tabla inexistente (`PGRST205`) sobre esa tabla durante ese mismo periodo. Hasta entonces SHALL conservarse.

#### Scenario: Aún hay usuarios activos en 1.8.x
- **WHEN** al evaluar el criterio de retiro hay al menos un usuario con sesión iniciada que usó la `1.8.x` en los últimos 14 días
- **THEN** la tabla se conserva y el criterio se vuelve a evaluar más adelante

#### Scenario: Ya no hay usuarios activos en 1.8.x
- **WHEN** ningún usuario con sesión iniciada usó la `1.8.x` en los últimos 14 días y no hay eventos nuevos de `PGRST205` sobre esa tabla en ese periodo
- **THEN** la tabla se elimina mediante una migración, y los eventos de error asociados pueden darse por resueltos

#### Scenario: El retiro no deja errores nuevos
- **WHEN** se elimina la tabla cumpliendo el criterio
- **THEN** no aparecen eventos nuevos de `PGRST205` sobre `daily_summary_free_usage` en el seguimiento de errores
