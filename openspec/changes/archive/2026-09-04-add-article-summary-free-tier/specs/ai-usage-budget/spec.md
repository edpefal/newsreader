## MODIFIED Requirements

### Requirement: Límite diario de resúmenes de artículo por usuario
El sistema SHALL mantener, por usuario, un contador de resúmenes de artículo generados exitosamente (capability `article-summaries`, incluyendo la detección de menciones de `article-mentions` que viaja en el mismo request) en el día en curso (día del servidor). El límite diario vigente SHALL depender de si el usuario tiene suscripción activa al momento de la solicitud: 25 resúmenes con suscripción activa, 2 resúmenes sin ella. Ambos casos SHALL compartir el mismo contador diario del usuario — no son cupos independientes que se acumulen; si un usuario sin suscripción consume parte de su cupo gratis y luego se suscribe el mismo día, el contador ya consumido SHALL descontarse del límite de 25, no resetearse. Cada resumen de artículo generado exitosamente SHALL contar como exactamente 1 unidad contra el límite vigente en el momento de esa generación, sin importar la longitud del artículo resumido. La capability `daily-summaries` (resumen diario) NO SHALL consumir ni chequear este límite — se limita en su lugar a su propio cupo, según su propia spec.

#### Scenario: Consumo dentro del límite diario, con suscripción activa
- **WHEN** una solicitud de `article-summaries` de un usuario con suscripción activa va a invocar a la API de IA y el consumo ya registrado hoy para ese usuario es menor a 25 resúmenes
- **THEN** el sistema permite la invocación y, si genera el resumen exitosamente, incrementa en 1 el consumo del día

#### Scenario: Consumo alcanza el límite diario, con suscripción activa
- **WHEN** el consumo ya registrado hoy para un usuario con suscripción activa es de 25 resúmenes y llega una nueva solicitud de `article-summaries`
- **THEN** el sistema rechaza la solicitud sin invocar a la API de IA, sin incrementar el consumo, y responde con un error distinguible de otros errores de generación

#### Scenario: Consumo dentro del límite diario gratis, sin suscripción activa
- **WHEN** una solicitud de `article-summaries` de un usuario sin suscripción activa va a invocar a la API de IA y el consumo ya registrado hoy para ese usuario es menor a 2 resúmenes
- **THEN** el sistema permite la invocación y, si genera el resumen exitosamente, incrementa en 1 el consumo del día

#### Scenario: Consumo alcanza el límite diario gratis, sin suscripción activa
- **WHEN** el consumo ya registrado hoy para un usuario sin suscripción activa es de 2 resúmenes y llega una nueva solicitud de `article-summaries` de ese mismo usuario, sin suscripción activa
- **THEN** el sistema rechaza la solicitud sin invocar a la API de IA, sin incrementar el consumo, y responde con el mismo error de límite alcanzado usado para un usuario con suscripción activa que llega a 25

#### Scenario: Consumo previo sin suscripción se descuenta del límite tras suscribirse el mismo día
- **WHEN** un usuario consumió 2 resúmenes de artículo hoy sin suscripción activa y luego, el mismo día, activa una suscripción
- **THEN** el sistema le permite generar hasta 23 resúmenes adicionales ese mismo día (25 menos los 2 ya consumidos), sin resetear el contador del día

#### Scenario: El resumen diario no consume ni chequea este límite
- **WHEN** el usuario genera un resumen diario (capability `daily-summaries`)
- **THEN** el sistema no consulta ni descuenta nada de este límite — esa generación se limita únicamente por su propia spec
