## MODIFIED Requirements

### Requirement: Presupuesto diario de palabras de input por usuario
El sistema SHALL mantener, por usuario, un contador de palabras de input consumidas por las features de IA cubiertas por este presupuesto (`article-summaries` y `article-mentions` — resumen de un artículo individual y detección de menciones) en el día en curso (día del servidor). El límite diario SHALL ser de 30,000 palabras. Solo SHALL contarse el texto enviado como input a la API de IA (títulos y contenido de artículos); el texto que la API de IA devuelve como respuesta NO SHALL contarse contra el presupuesto. La capability `daily-summaries` (resumen diario) NO SHALL consumir ni chequear este presupuesto — se limita en su lugar a una generación por día, según su propia spec.

#### Scenario: Consumo dentro del presupuesto
- **WHEN** una solicitud de `article-summaries` o `article-mentions` va a invocar a la API de IA y la suma de palabras de esa solicitud más el consumo ya registrado hoy para ese usuario no supera las 30,000 palabras
- **THEN** el sistema permite la invocación y registra esas palabras como consumidas del día

#### Scenario: Consumo excede el presupuesto
- **WHEN** la suma de palabras de una solicitud de `article-summaries` o `article-mentions` más el consumo ya registrado hoy para ese usuario superaría las 30,000 palabras
- **THEN** el sistema rechaza la solicitud sin invocar a la API de IA, sin registrar ningún consumo adicional, y responde con un error distinguible de otros errores de generación

#### Scenario: El resumen diario no consume ni chequea este presupuesto
- **WHEN** el usuario genera un resumen diario (capability `daily-summaries`)
- **THEN** el sistema no consulta ni descuenta nada de este presupuesto de palabras — esa generación se limita únicamente por la regla de "una generación por día" de `daily-summaries`
