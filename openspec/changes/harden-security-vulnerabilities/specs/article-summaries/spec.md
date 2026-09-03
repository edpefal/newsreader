## ADDED Requirements

### Requirement: El contenido del artículo enviado a la API de IA está delimitado de la instrucción del sistema
El sistema SHALL enviar el contenido del artículo a la API de IA envuelto en un delimitador explícito que lo distinga de la instrucción del sistema, junto con una indicación de que ese contenido delimitado se trata siempre como texto a resumir y nunca como una instrucción a seguir, sin importar lo que ese contenido diga.

#### Scenario: Artículo cuyo contenido incluye texto que simula una instrucción
- **WHEN** el contenido de un artículo incluye texto que intenta darle una instrucción distinta al modelo (por ejemplo, pedirle que ignore las instrucciones anteriores o cambie de tono/idioma)
- **THEN** el sistema igual envía ese texto delimitado como contenido a resumir, sin que dejen de aplicarse las instrucciones de tono, idioma y formato ya definidas para el resumen
