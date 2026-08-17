## MODIFIED Requirements

### Requirement: Generación de resumen diario del inbox
El sistema SHALL generar, mediante una API de IA en la nube, un resumen de texto agrupado por fuente a partir del título y el contenido de los artículos del inbox (no leídos, no archivados) cuyo `publishedAt` corresponde a la fecha actual. Para cada artículo, el contenido usado SHALL ser el texto plano extraído de `contentHtml` cuando el artículo tiene contenido completo (no truncado); si `contentHtml` está truncado o vacío, SHALL usarse `excerpt` como fallback. El texto generado por fuente SHALL tener una voz narrativa consistente (tono cercano y con personalidad, sin emojis, en español latinoamericano neutro con tuteo), aplicada por igual sin importar el tono original de cada fuente.

Además del texto combinado, el sistema SHALL persistir junto al `DailySummary` la agrupación por fuente usada para armar la solicitud a la API de IA (identificador y nombre de cada fuente, junto con los ids de los artículos de esa fuente incluidos ese día), sin alterar el prompt ni la solicitud enviada a la API de IA.

Generar un resumen SHALL requerir una suscripción activa (ver capability `subscription-entitlements`). El sistema SHALL verificar esto tanto en la UI (mostrando el paywall si no hay suscripción activa, en vez de disparar la generación) como en el backend (rechazando la solicitud sin invocar a la API de IA si el usuario autenticado no tiene una suscripción activa).

#### Scenario: Generar resumen con artículos disponibles
- **WHEN** el usuario con suscripción activa toca "Crear resumen" y el inbox tiene al menos un artículo publicado hoy
- **THEN** el sistema agrupa esos artículos por fuente, genera un párrafo por cada fuente (prefijado con su nombre) invocando la API de IA, y al finalizar crea o actualiza el `DailySummary` del día de hoy con el texto combinado

#### Scenario: Usuario sin suscripción activa ve el paywall al intentar generar
- **WHEN** el usuario sin suscripción activa toca "Crear resumen" o "Regenerar resumen de hoy"
- **THEN** el sistema muestra el paywall de Superwall en vez de disparar la generación

#### Scenario: Backend rechaza la generación sin suscripción activa
- **WHEN** `summarize-articles` recibe una solicitud de un usuario autenticado cuya suscripción no está activa en la tabla de entitlements
- **THEN** el backend responde con un error de suscripción requerida y no invoca a la API de IA
