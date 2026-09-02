## MODIFIED Requirements

### Requirement: Límite diario de resúmenes de artículo por usuario
El sistema SHALL mantener, por usuario, un contador de resúmenes de artículo generados exitosamente (capability `article-summaries`, incluyendo la detección de menciones de `article-mentions` que viaja en el mismo request) en el día en curso (día del servidor). El límite diario SHALL ser de 25 resúmenes. Cada resumen de artículo generado exitosamente SHALL contar como exactamente 1 unidad contra este límite, sin importar la longitud del artículo resumido. La capability `daily-summaries` (resumen diario) NO SHALL consumir ni chequear este límite — se limita en su lugar a una generación por día, según su propia spec.

#### Scenario: Consumo dentro del límite diario
- **WHEN** una solicitud de `article-summaries` va a invocar a la API de IA y el consumo ya registrado hoy para ese usuario es menor a 25 resúmenes
- **THEN** el sistema permite la invocación y, si genera el resumen exitosamente, incrementa en 1 el consumo del día

#### Scenario: Consumo alcanza el límite diario
- **WHEN** el consumo ya registrado hoy para ese usuario es de 25 resúmenes y llega una nueva solicitud de `article-summaries`
- **THEN** el sistema rechaza la solicitud sin invocar a la API de IA, sin incrementar el consumo, y responde con un error distinguible de otros errores de generación

#### Scenario: El resumen diario no consume ni chequea este límite
- **WHEN** el usuario genera un resumen diario (capability `daily-summaries`)
- **THEN** el sistema no consulta ni descuenta nada de este límite — esa generación se limita únicamente por la regla de "una generación por día" de `daily-summaries`

### Requirement: Chequeo e incremento atómicos
El sistema SHALL chequear el consumo disponible e incrementarlo como una única operación atómica del lado del servidor, de forma que dos solicitudes concurrentes del mismo usuario no puedan ambas pasar el chequeo y hacer que el consumo total termine superando el límite diario de 25 resúmenes.

#### Scenario: Dos solicitudes concurrentes cerca del límite
- **WHEN** el usuario tiene 24 resúmenes consumidos hoy y dispara dos solicitudes de resumen casi al mismo tiempo
- **THEN** el sistema permite como máximo 1 de esas solicitudes, rechazando la otra

### Requirement: Reset diario del límite
El sistema SHALL resetear el consumo registrado de un usuario a cero al comenzar un nuevo día (día del servidor), sin necesidad de una tarea de limpieza programada aparte — el primer chequeo del nuevo día SHALL detectar el cambio de día y resetear el contador antes de aplicar el chequeo.

#### Scenario: Primera solicitud de un nuevo día
- **WHEN** un usuario con consumo registrado de un día anterior dispara una solicitud de resumen en un día distinto
- **THEN** el sistema trata el consumo previo como si no existiera (contador en cero para el día nuevo) antes de aplicar el chequeo del límite de esa solicitud

### Requirement: Consulta de estado de uso
El sistema SHALL permitir que el usuario autenticado consulte su propio consumo del día en curso y el límite diario vigente, sin poder consultar ni modificar el consumo de ningún otro usuario.

#### Scenario: Usuario consulta su propio consumo
- **WHEN** el usuario autenticado consulta su estado de uso de IA
- **THEN** el sistema devuelve la cantidad de resúmenes generados hoy y el límite diario vigente para ese usuario

#### Scenario: Usuario sin consumo previo
- **WHEN** un usuario que nunca generó un resumen de artículo consulta su estado de uso
- **THEN** el sistema devuelve 0 resúmenes generados y el límite diario vigente

## ADDED Requirements

### Requirement: Techo de longitud por artículo individual
El sistema SHALL rechazar generar el resumen automático de un artículo cuyo contenido (texto plano de input enviado a la API de IA) supere las 8,000 palabras, sin invocar a la API de IA y sin incrementar el consumo del límite diario de resúmenes. Este techo SHALL aplicarse independientemente del consumo diario disponible del usuario (incluso con el contador en 0, un artículo que supera el techo SHALL rechazarse igual), y SHALL responder con un error distinguible del error de límite diario alcanzado.

#### Scenario: Artículo dentro del techo de longitud
- **WHEN** el contenido de input de un artículo tiene 8,000 palabras o menos
- **THEN** el sistema aplica el chequeo normal del límite diario de resúmenes, sin rechazar por longitud

#### Scenario: Artículo supera el techo de longitud
- **WHEN** el contenido de input de un artículo supera las 8,000 palabras
- **THEN** el sistema rechaza la solicitud sin invocar a la API de IA, sin descontar del límite diario de resúmenes, y responde con un error específico de artículo demasiado largo
