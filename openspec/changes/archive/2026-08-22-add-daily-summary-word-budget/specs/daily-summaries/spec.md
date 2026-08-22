## MODIFIED Requirements

### Requirement: Generación de resumen diario del inbox
El sistema SHALL generar, mediante una API de IA en la nube, un resumen de texto agrupado por fuente a partir del título y el contenido de los artículos del inbox (no leídos, no archivados) cuyo `publishedAt` corresponde a la fecha actual. Para cada artículo, el contenido usado SHALL ser el texto plano extraído de `contentHtml` cuando el artículo tiene contenido completo (no truncado); si `contentHtml` está truncado o vacío, SHALL usarse `excerpt` como fallback. El texto generado por fuente SHALL tener una voz narrativa consistente (tono cercano y con personalidad, sin emojis, en español latinoamericano neutro con tuteo), aplicada por igual sin importar el tono original de cada fuente.

Además del texto combinado, el sistema SHALL persistir junto al `DailySummary` la agrupación por fuente usada para armar la solicitud a la API de IA (identificador y nombre de cada fuente, junto con los ids de los artículos de esa fuente incluidos ese día), sin alterar el prompt ni la solicitud enviada a la API de IA.

La solicitud a la API de IA SHALL autenticarse con el access token de la sesión activa del usuario. El backend SHALL rechazar con un error de autenticación cualquier solicitud cuyo token no corresponda a una sesión de usuario autenticada (incluyendo solicitudes hechas con una key pública/anónima en vez de una sesión real), sin invocar a la API de IA en ese caso.

Generar un resumen SHALL requerir una suscripción activa (ver capability `subscription-entitlements`). El sistema SHALL verificar esto tanto en la UI (mostrando el paywall si no hay suscripción activa, en vez de disparar la generación) como en el backend (rechazando la solicitud sin invocar a la API de IA si el usuario autenticado no tiene una suscripción activa).

La generación SHALL además estar sujeta al presupuesto diario de palabras de la capability `ai-usage-budget`: si generar excedería el presupuesto disponible del usuario para el día en curso, el backend SHALL rechazar la solicitud sin invocar a la API de IA, y el sistema SHALL mostrar un estado de error distinguible de los demás (indicando que se alcanzó el límite diario de IA, no un error de red ni de suscripción).

#### Scenario: Generar resumen con artículos disponibles
- **WHEN** el usuario con suscripción activa toca "Crear resumen" y el inbox tiene al menos un artículo publicado hoy
- **THEN** el sistema agrupa esos artículos por fuente, genera un párrafo por cada fuente (prefijado con su nombre) invocando la API de IA, y al finalizar crea o actualiza el `DailySummary` del día de hoy con el texto combinado

#### Scenario: Usuario sin suscripción activa ve el paywall al intentar generar
- **WHEN** el usuario sin suscripción activa toca "Crear resumen" o "Regenerar resumen de hoy"
- **THEN** el sistema muestra el paywall de Superwall en vez de disparar la generación

#### Scenario: Backend rechaza la generación sin suscripción activa
- **WHEN** `summarize-articles` recibe una solicitud de un usuario autenticado cuya suscripción no está activa en la tabla de entitlements
- **THEN** el backend responde con un error de suscripción requerida y no invoca a la API de IA

#### Scenario: Artículo con contenido completo usa el texto extraído de contentHtml
- **WHEN** un artículo del inbox de hoy tiene `contentHtml` no truncado (mismo criterio que `FeedContentChecker.isTruncated`)
- **THEN** el sistema usa el texto plano extraído de `contentHtml` (sin tags HTML) como contenido de ese artículo en el resumen, sin límite de longitud

#### Scenario: Artículo con contenido truncado usa excerpt como fallback
- **WHEN** un artículo del inbox de hoy tiene `contentHtml` truncado o vacío (mismo criterio que `FeedContentChecker.isTruncated`)
- **THEN** el sistema usa `excerpt` como contenido de ese artículo en el resumen, igual que el comportamiento anterior

#### Scenario: Solicitud sin sesión de usuario activa
- **WHEN** no hay una sesión de usuario activa en el dispositivo
- **THEN** el sistema no envía ninguna solicitud al backend de generación de resumen, y falla con un error indicando que se requiere sesión activa

#### Scenario: Backend rechaza solicitudes sin sesión de usuario autenticada
- **WHEN** el backend de generación de resumen recibe una solicitud cuyo token no corresponde a una sesión de usuario autenticada (ej. una key anónima/pública)
- **THEN** el backend responde con un error de autenticación y no invoca a la API de IA

#### Scenario: El párrafo de cada fuente tiene voz consistente, sin emojis
- **WHEN** se genera el resumen diario para cualquier fuente, sin importar su tono editorial original
- **THEN** el párrafo resultante usa la misma voz narrativa con personalidad (español latinoamericano neutro, tuteo, sin emojis), no un tono adaptado al estilo de esa fuente en particular

#### Scenario: Botón deshabilitado sin artículos de hoy
- **WHEN** el inbox no tiene artículos con `publishedAt` de la fecha actual
- **THEN** el botón "Crear resumen" SHALL estar deshabilitado y no SHALL invocarse la API de IA

#### Scenario: Falla la generación del resumen
- **WHEN** la llamada a la API de IA falla (sin red, error del backend, respuesta inválida, etc.)
- **THEN** el sistema SHALL mostrar un estado de error distinguible del estado "sin artículos", permitiendo reintentar

#### Scenario: Se persiste la agrupación por fuente junto al resumen
- **WHEN** el sistema genera exitosamente un `DailySummary`
- **THEN** además del texto combinado, persiste para cada fuente incluida ese día su identificador, nombre, y la lista de ids de los artículos de esa fuente usados en el resumen

#### Scenario: Rechazo por presupuesto diario de IA agotado
- **WHEN** el usuario toca "Crear resumen" o "Regenerar resumen de hoy" y generar excedería el presupuesto diario de palabras disponible para ese usuario
- **THEN** el backend rechaza la solicitud sin invocar a la API de IA, y el sistema muestra un estado de error que indica específicamente que se alcanzó el límite diario de IA, distinto del estado de error genérico de falla de generación

## ADDED Requirements

### Requirement: Medidor visible de consumo de IA
El sistema SHALL mostrar en la pantalla de Resúmenes un indicador visible del consumo de IA del día en curso (palabras consumidas y límite diario, ver capability `ai-usage-budget`), y SHALL deshabilitar el botón de generar cuando el consumo del día alcanzó el límite diario, hasta el reset del día siguiente.

#### Scenario: Medidor muestra el consumo actual
- **WHEN** el usuario entra a la pantalla de Resúmenes
- **THEN** el sistema muestra cuántas palabras se consumieron hoy y cuál es el límite diario

#### Scenario: Botón deshabilitado al agotar el presupuesto
- **WHEN** el consumo de IA del día alcanzó el límite diario
- **THEN** el botón de generar/regenerar el resumen de hoy SHALL estar deshabilitado, sin importar si hay artículos nuevos, hasta que el presupuesto resetee al día siguiente

### Requirement: Confirmación antes de regenerar sin artículos nuevos
Cuando ya existe un `DailySummary` para el día de hoy y la cantidad de artículos de hoy en el inbox es igual a `articleCount` de ese resumen ya guardado (es decir, no llegó ningún artículo nuevo desde la última generación), el sistema SHALL pedir confirmación explícita al usuario antes de invocar la API de IA para regenerar. Si el usuario cancela, el sistema NO SHALL invocar la API de IA ni modificar el `DailySummary` existente. Cuando la cantidad de artículos de hoy es distinta a la del resumen guardado (llegaron artículos nuevos), el sistema NO SHALL pedir esta confirmación y SHALL proceder directo a generar.

#### Scenario: Regenerar sin artículos nuevos pide confirmación
- **WHEN** el usuario toca "Regenerar resumen de hoy" y la cantidad de artículos de hoy en el inbox es igual a la del `DailySummary` ya guardado para hoy
- **THEN** el sistema muestra un diálogo de confirmación antes de invocar la API de IA

#### Scenario: Confirmar procede con la regeneración
- **WHEN** el usuario confirma el diálogo de "¿regenerar igual?"
- **THEN** el sistema invoca la API de IA y sobrescribe el `DailySummary` de hoy, igual que una regeneración normal

#### Scenario: Cancelar no genera ni gasta presupuesto
- **WHEN** el usuario cancela el diálogo de "¿regenerar igual?"
- **THEN** el sistema no invoca la API de IA, no modifica el `DailySummary` existente, y no descuenta nada del presupuesto diario de IA

#### Scenario: Artículos nuevos no piden confirmación
- **WHEN** el usuario toca "Regenerar resumen de hoy" y la cantidad de artículos de hoy en el inbox es distinta (mayor) a la del `DailySummary` ya guardado para hoy
- **THEN** el sistema invoca la API de IA directamente, sin mostrar ningún diálogo de confirmación
