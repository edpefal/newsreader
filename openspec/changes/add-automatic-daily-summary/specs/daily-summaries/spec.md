## MODIFIED Requirements

### Requirement: Generación de resumen diario del inbox
El sistema SHALL generar, mediante una API de IA en la nube, un resumen de texto agrupado por fuente a partir del título y el contenido de los artículos del inbox (no leídos, no archivados) cuyo `publishedAt` corresponde a la fecha actual **en la zona horaria local de ese usuario** (derivada de su offset horario persistido en la capability `user-preferences`). Para cada artículo, el contenido usado SHALL ser el texto plano extraído de `contentHtml` cuando el artículo tiene contenido completo (no truncado); si `contentHtml` está truncado o vacío, SHALL usarse `excerpt` como fallback. El texto generado por fuente SHALL tener una voz narrativa consistente (tono cercano y con personalidad, sin emojis), aplicada por igual sin importar el tono original de cada fuente, y SHALL generarse en el idioma persistido para ese usuario en `user-preferences`, de entre los idiomas que `AppLocalizations` soporta (inglés, español, francés). Si el locale persistido no está entre los soportados, o el usuario no tiene ninguna preferencia sincronizada todavía, el sistema SHALL usar inglés como default.

Además del texto combinado, el sistema SHALL persistir junto al `DailySummary` la agrupación por fuente usada para armar la solicitud a la API de IA (identificador y nombre de cada fuente, junto con los ids de los artículos de esa fuente incluidos ese día), sin alterar el prompt ni la solicitud enviada a la API de IA.

La generación SHALL ejecutarse del lado del servidor con privilegios de `service_role`, disparada automáticamente (ver Requirement "Disparo automático de la generación, sin acción del usuario"), sin depender de una sesión de usuario activa ni de un token de acceso enviado por un cliente.

La generación SHALL estar limitada a una única generación exitosa por día local por usuario (ver Requirement "Un único resumen por día, sin regeneración"): si ya existe un `DailySummary` para el día de hoy (local) de ese usuario, el sistema SHALL omitir a ese usuario en esa corrida, sin invocar la API de IA ni sobreescribir el `DailySummary` existente.

#### Scenario: Generar resumen con artículos disponibles
- **WHEN** un usuario elegible (ver Requirement "Elegibilidad: suscripción activa o lunes sin suscripción") tiene al menos un artículo publicado hoy (local) en su inbox, y todavía no tiene un `DailySummary` de hoy
- **THEN** el sistema agrupa esos artículos por fuente, genera un párrafo por cada fuente (prefijado con su nombre) invocando la API de IA, y al finalizar crea el `DailySummary` del día de hoy (local) con el texto combinado

#### Scenario: Artículo con contenido completo usa el texto extraído de contentHtml
- **WHEN** un artículo del inbox de hoy (local) tiene `contentHtml` no truncado (mismo criterio que `FeedContentChecker.isTruncated`)
- **THEN** el sistema usa el texto plano extraído de `contentHtml` (sin tags HTML) como contenido de ese artículo en el resumen, sin límite de longitud

#### Scenario: Artículo con contenido truncado usa excerpt como fallback
- **WHEN** un artículo del inbox de hoy (local) tiene `contentHtml` truncado o vacío (mismo criterio que `FeedContentChecker.isTruncated`)
- **THEN** el sistema usa `excerpt` como contenido de ese artículo en el resumen, igual que el comportamiento anterior

#### Scenario: El párrafo de cada fuente tiene voz consistente, sin emojis
- **WHEN** se genera el resumen diario para cualquier fuente, sin importar su tono editorial original
- **THEN** el párrafo resultante usa la misma voz narrativa con personalidad (sin emojis) y en el mismo idioma para todas las fuentes de ese resumen, no un tono ni idioma adaptado al estilo de esa fuente en particular

#### Scenario: El resumen se genera en el idioma persistido del usuario
- **WHEN** un usuario tiene un locale soportado (inglés, español o francés) persistido en `user-preferences`
- **THEN** el texto del resumen se genera en ese mismo idioma, para todas las fuentes incluidas

#### Scenario: Sin preferencia de locale persistida cae a inglés
- **WHEN** un usuario no tiene ningún locale persistido en `user-preferences`, o el valor persistido no es ninguno de los soportados
- **THEN** el sistema genera el resumen en inglés como default seguro

#### Scenario: Falla la generación del resumen
- **WHEN** la llamada a la API de IA falla (error del backend, respuesta inválida, etc.) para un usuario elegible
- **THEN** el sistema no persiste ningún `DailySummary` para ese usuario en esa corrida, dejando la posibilidad de reintentar en la siguiente (ver Requirement "Reintento automático dentro del mismo día local")

#### Scenario: Se persiste la agrupación por fuente junto al resumen
- **WHEN** el sistema genera exitosamente un `DailySummary`
- **THEN** además del texto combinado, persiste para cada fuente incluida ese día su identificador, nombre, y la lista de ids de los artículos de esa fuente usados en el resumen

#### Scenario: Usuario con DailySummary de hoy ya generado se omite
- **WHEN** el sistema evalúa a un usuario que ya tiene un `DailySummary` para su día de hoy (local)
- **THEN** el sistema no invoca la API de IA para ese usuario en esa corrida, ni modifica el `DailySummary` existente

### Requirement: Un único resumen por día, sin regeneración
El sistema SHALL mantener como máximo un `DailySummary` por fecha local por usuario, y SHALL permitir como máximo una generación exitosa por fecha local por usuario. Una vez generado el resumen de un día, ese `DailySummary` SHALL permanecer sin cambios hasta que el usuario elimine su fuente en cascada (ver capability `source-management`) — no existe ninguna acción, automática o de usuario, que lo modifique o regenere ese mismo día.

#### Scenario: Nuevo día crea un nuevo resumen
- **WHEN** el sistema genera un resumen para una fecha local distinta a la de cualquier `DailySummary` existente de ese usuario
- **THEN** el sistema crea un nuevo `DailySummary` para esa fecha, dejando intactos los resúmenes de días anteriores

#### Scenario: Un segundo intento el mismo día local no modifica el resumen existente
- **WHEN** ya existe un `DailySummary` para la fecha local de hoy de un usuario, y el sistema vuelve a evaluar a ese usuario en una corrida posterior el mismo día
- **THEN** el sistema no invoca la API de IA ni modifica el `DailySummary` existente de hoy

## ADDED Requirements

### Requirement: Disparo automático de la generación, sin acción del usuario
El sistema SHALL evaluar periódicamente, sin que ningún usuario dispare la acción, si corresponde generar el `DailySummary` de hoy (local) de cada usuario. El sistema SHALL considerar a un usuario listo para evaluación una vez que su hora local actual (derivada de su offset horario persistido en `user-preferences`) alcanza un umbral fijo razonablemente temprano en la mañana.

#### Scenario: Usuario cuya hora local ya pasó el umbral
- **WHEN** la hora local actual de un usuario ya pasó el umbral de generación, y no tiene un `DailySummary` de hoy (local) todavía
- **THEN** el sistema evalúa su elegibilidad (ver Requirement "Elegibilidad: suscripción activa o lunes sin suscripción") y, si es elegible y tiene artículos de hoy, genera su resumen sin que el usuario haga nada

#### Scenario: Usuario cuya hora local todavía no pasó el umbral
- **WHEN** la hora local actual de un usuario todavía no alcanza el umbral de generación
- **THEN** el sistema no intenta generar su resumen de hoy en esa corrida, sin importar su elegibilidad

### Requirement: Elegibilidad: suscripción activa o lunes sin suscripción
El sistema SHALL considerar elegible para la generación automática de hoy (local) a un usuario si: (a) tiene una suscripción activa (ver capability `subscription-entitlements`), cualquier día de la semana; o (b) no tiene suscripción activa, pero su fecha local de hoy cae en lunes. Un usuario sin suscripción activa cuya fecha local de hoy no es lunes NO SHALL ser elegible ese día.

#### Scenario: Usuario con suscripción activa es elegible cualquier día
- **WHEN** un usuario tiene suscripción activa, sin importar el día de la semana en su fecha local
- **THEN** el sistema lo considera elegible para la generación automática de hoy

#### Scenario: Usuario sin suscripción es elegible solo los lunes
- **WHEN** un usuario no tiene suscripción activa y su fecha local de hoy es lunes
- **THEN** el sistema lo considera elegible para la generación automática de hoy

#### Scenario: Usuario sin suscripción no es elegible el resto de la semana
- **WHEN** un usuario no tiene suscripción activa y su fecha local de hoy no es lunes
- **THEN** el sistema no lo considera elegible para la generación automática de hoy, y no genera ningún `DailySummary` para él en esa fecha

### Requirement: Reintento automático dentro del mismo día local
Si la generación automática de un usuario falla en una corrida (ver Requirement "Generación de resumen diario del inbox", escenario de falla), el sistema SHALL reintentarla en la siguiente corrida, siempre que siga siendo la misma fecha local de ese usuario y todavía no tenga un `DailySummary` para esa fecha. El sistema NO SHALL reintentar retroactivamente una fecha local que ya pasó.

#### Scenario: Reintento exitoso en la corrida siguiente
- **WHEN** la generación de un usuario elegible falló en una corrida, y en la siguiente corrida sigue siendo la misma fecha local de ese usuario y todavía no tiene un `DailySummary` de hoy
- **THEN** el sistema vuelve a intentar la generación para ese usuario

#### Scenario: Sin reintento retroactivo tras el cambio de día local
- **WHEN** la generación de un usuario falló en todas las corridas de un día local, y ese día local ya terminó (cambió la fecha local del usuario)
- **THEN** el sistema no genera un `DailySummary` retroactivo para la fecha que falló; solo evalúa la generación de la nueva fecha local en curso

## REMOVED Requirements

### Requirement: Indicador de cupo gratis antes de generar
**Reason**: Ya no existe una acción manual de "generar" ni un cupo consumible a demanda — la elegibilidad gratis pasa a ser automática y fija (lunes), sin cupo que mostrar ni agotar (ver Requirement "Elegibilidad: suscripción activa o lunes sin suscripción").
**Migration**: Ninguna acción de usuario ni de datos requerida — el indicador y el flujo que dependían de él se eliminan de la UI.

### Requirement: Indicador de resumen ya generado hoy
**Reason**: Dependía de un botón de generar que ya no existe. El estado "resumen de hoy generado o no" ahora se refleja simplemente en si el `DailySummary` de hoy aparece en el listado (ver Requirement "Listado de resúmenes diarios", que no cambia), sin necesitar un indicador ni un botón que deshabilitar.
**Migration**: Ninguna acción de usuario ni de datos requerida — el indicador se elimina de la UI.
