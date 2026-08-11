## MODIFIED Requirements

### Requirement: Generación de resumen diario del inbox
El sistema SHALL generar, mediante una API de IA en la nube, un resumen de texto agrupado por fuente a partir del título y el contenido de los artículos del inbox (no leídos, no archivados) cuyo `publishedAt` corresponde a la fecha actual. Para cada artículo, el contenido usado SHALL ser el texto plano extraído de `contentHtml` cuando el artículo tiene contenido completo (no truncado); si `contentHtml` está truncado o vacío, SHALL usarse `excerpt` como fallback. El texto generado por fuente SHALL tener una voz narrativa consistente (tono cercano y con personalidad, sin emojis, en español latinoamericano neutro con tuteo), aplicada por igual sin importar el tono original de cada fuente.

Además del texto combinado, el sistema SHALL persistir junto al `DailySummary` la agrupación por fuente usada para armar la solicitud a la API de IA (identificador y nombre de cada fuente, junto con los ids de los artículos de esa fuente incluidos ese día), sin alterar el prompt ni la solicitud enviada a la API de IA.

La solicitud a la API de IA SHALL autenticarse con el access token de la sesión activa del usuario. El backend SHALL rechazar con un error de autenticación cualquier solicitud cuyo token no corresponda a una sesión de usuario autenticada (incluyendo solicitudes hechas con una key pública/anónima en vez de una sesión real), sin invocar a la API de IA en ese caso.

#### Scenario: Generar resumen con artículos disponibles
- **WHEN** el usuario toca "Crear resumen" y el inbox tiene al menos un artículo publicado hoy
- **THEN** el sistema agrupa esos artículos por fuente, genera un párrafo por cada fuente (prefijado con su nombre) invocando la API de IA, y al finalizar crea o actualiza el `DailySummary` del día de hoy con el texto combinado

#### Scenario: Solicitud sin sesión de usuario activa
- **WHEN** no hay una sesión de usuario activa en el dispositivo
- **THEN** el sistema no envía ninguna solicitud al backend de generación de resumen, y falla con un error indicando que se requiere sesión activa

#### Scenario: Backend rechaza solicitudes sin sesión de usuario autenticada
- **WHEN** el backend de generación de resumen recibe una solicitud cuyo token no corresponde a una sesión de usuario autenticada (ej. una key anónima/pública)
- **THEN** el backend responde con un error de autenticación y no invoca a la API de IA
