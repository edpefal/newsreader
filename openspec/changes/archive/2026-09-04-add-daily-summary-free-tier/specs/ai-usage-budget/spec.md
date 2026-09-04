## ADDED Requirements

### Requirement: Límite semanal gratis de resumen diario por usuario
El sistema SHALL mantener, por usuario, un contador de resúmenes diarios (capability `daily-summaries`) generados exitosamente sin suscripción activa, en la semana calendario en curso (semana ISO, reset los lunes, día de servidor). El límite semanal SHALL ser de 1 resumen diario. Este límite SHALL aplicarse únicamente cuando el usuario no tiene suscripción activa: un usuario con suscripción activa SHALL generar sin consultar ni descontar este contador. Este límite es independiente del límite diario de `article-summaries` definido en este mismo capability, y ninguno de los dos consume al otro.

Un intento de generación que sea rechazado por no tener artículos de hoy, o por ya existir un `DailySummary` del día de hoy para ese usuario, NO SHALL descontar este contador — el descuento SHALL ocurrir únicamente cuando el backend invoca la API de IA y persiste el `DailySummary` exitosamente.

#### Scenario: Usuario sin suscripción con cupo gratis semanal disponible
- **WHEN** una solicitud de `daily-summaries` de un usuario sin suscripción activa va a invocar a la API de IA, y ese usuario no generó ningún resumen diario gratis en la semana calendario en curso
- **THEN** el sistema permite la invocación y, si el resumen se genera y persiste exitosamente, incrementa en 1 el consumo semanal gratis de ese usuario

#### Scenario: Usuario sin suscripción con cupo gratis semanal ya consumido
- **WHEN** un usuario sin suscripción activa ya generó 1 resumen diario gratis en la semana calendario en curso y llega una nueva solicitud de `daily-summaries` de ese usuario
- **THEN** el sistema rechaza la solicitud sin invocar a la API de IA, sin incrementar el consumo semanal, y responde con el mismo error de "suscripción requerida" usado cuando no hay suscripción ni cupo

#### Scenario: Usuario con suscripción activa no consume este límite
- **WHEN** un usuario con suscripción activa genera un resumen diario, sin importar su consumo semanal gratis previo
- **THEN** el sistema no consulta ni descuenta nada de este límite semanal

### Requirement: Reset semanal del límite gratis de resumen diario
El sistema SHALL resetear el consumo semanal gratis de resumen diario de un usuario a cero al comenzar una nueva semana calendario (lunes, día de servidor), sin necesidad de una tarea de limpieza programada aparte — el primer chequeo de la nueva semana SHALL detectar el cambio de semana y resetear el contador antes de aplicar el chequeo.

#### Scenario: Primera solicitud gratis de una nueva semana calendario
- **WHEN** un usuario con consumo semanal gratis registrado de una semana calendario anterior dispara una solicitud de resumen diario sin suscripción activa en una semana calendario distinta
- **THEN** el sistema trata el consumo previo como si no existiera (contador en cero para la semana nueva) antes de aplicar el chequeo del límite de esa solicitud

### Requirement: Chequeo e incremento atómicos del límite semanal gratis
El sistema SHALL chequear el consumo semanal gratis disponible e incrementarlo como una única operación atómica del lado del servidor, de forma que dos solicitudes concurrentes sin suscripción activa del mismo usuario no puedan ambas pasar el chequeo y hacer que el consumo semanal termine superando el límite de 1.

#### Scenario: Dos solicitudes concurrentes sin suscripción con cupo disponible
- **WHEN** un usuario sin suscripción activa tiene 0 resúmenes diarios gratis consumidos en la semana en curso y dispara dos solicitudes de resumen diario casi al mismo tiempo
- **THEN** el sistema permite como máximo 1 de esas solicitudes, rechazando la otra

### Requirement: Consulta de estado del cupo gratis semanal
El sistema SHALL permitir que el usuario autenticado consulte su propio consumo semanal gratis de resumen diario y el límite semanal vigente, sin poder consultar ni modificar el consumo de ningún otro usuario. Esta consulta es independiente de la consulta de estado del límite diario de `article-summaries`.

#### Scenario: Usuario consulta su propio consumo semanal gratis
- **WHEN** el usuario autenticado consulta su estado de cupo gratis semanal de resumen diario
- **THEN** el sistema devuelve la cantidad de resúmenes diarios gratis generados en la semana calendario en curso y el límite semanal vigente para ese usuario

#### Scenario: Usuario sin consumo semanal gratis previo
- **WHEN** un usuario que nunca generó un resumen diario sin suscripción activa consulta su estado de cupo gratis semanal
- **THEN** el sistema devuelve 0 resúmenes gratis consumidos y el límite semanal vigente
