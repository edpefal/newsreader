## Purpose

Mantener, del lado del servidor, un presupuesto diario de palabras de input consumidas por el usuario en cualquier feature de IA de la app, para acotar el costo de las llamadas a la API de IA sin depender de que el cliente se autolimite.

## ADDED Requirements

### Requirement: Presupuesto diario de palabras de input por usuario
El sistema SHALL mantener, por usuario, un contador de palabras de input consumidas por features de IA en el día en curso (día del servidor). El límite diario SHALL ser de 30,000 palabras. Solo SHALL contarse el texto enviado como input a la API de IA (títulos y contenido de artículos); el texto que la API de IA devuelve como respuesta NO SHALL contarse contra el presupuesto.

#### Scenario: Consumo dentro del presupuesto
- **WHEN** una feature de IA va a invocar a la API de IA y la suma de palabras de esa solicitud más el consumo ya registrado hoy para ese usuario no supera las 30,000 palabras
- **THEN** el sistema permite la invocación y registra esas palabras como consumidas del día

#### Scenario: Consumo excede el presupuesto
- **WHEN** la suma de palabras de una solicitud más el consumo ya registrado hoy para ese usuario superaría las 30,000 palabras
- **THEN** el sistema rechaza la solicitud sin invocar a la API de IA, sin registrar ningún consumo adicional, y responde con un error distinguible de otros errores de generación

### Requirement: Chequeo e incremento atómicos
El sistema SHALL chequear el presupuesto disponible e incrementar el consumo registrado como una única operación atómica del lado del servidor, de forma que dos solicitudes concurrentes del mismo usuario no puedan ambas pasar el chequeo y hacer que el consumo total termine superando el presupuesto diario.

#### Scenario: Dos solicitudes concurrentes cerca del límite
- **WHEN** el usuario tiene consumo cercano al límite diario y dispara dos solicitudes de features de IA casi al mismo tiempo, donde ambas por separado entrarían en el presupuesto restante pero juntas lo superarían
- **THEN** el sistema permite como máximo la cantidad de esas solicitudes que efectivamente entre dentro del presupuesto, rechazando el resto

### Requirement: Reset diario del presupuesto
El sistema SHALL resetear el consumo registrado de un usuario a cero al comenzar un nuevo día (día del servidor), sin necesidad de una tarea de limpieza programada aparte — el primer chequeo del nuevo día SHALL detectar el cambio de día y resetear el contador antes de aplicar el chequeo.

#### Scenario: Primera solicitud de un nuevo día
- **WHEN** un usuario con consumo registrado de un día anterior dispara una solicitud de IA en un día distinto
- **THEN** el sistema trata el consumo previo como si no existiera (contador en cero para el día nuevo) antes de aplicar el chequeo de presupuesto de esa solicitud

### Requirement: Consulta de estado de uso
El sistema SHALL permitir que el usuario autenticado consulte su propio consumo del día en curso y el límite diario, sin poder consultar ni modificar el consumo de ningún otro usuario.

#### Scenario: Usuario consulta su propio consumo
- **WHEN** el usuario autenticado consulta su estado de uso de IA
- **THEN** el sistema devuelve las palabras consumidas hoy y el límite diario vigente para ese usuario

#### Scenario: Usuario sin consumo previo
- **WHEN** un usuario que nunca disparó una feature de IA consulta su estado de uso
- **THEN** el sistema devuelve 0 palabras consumidas y el límite diario vigente
