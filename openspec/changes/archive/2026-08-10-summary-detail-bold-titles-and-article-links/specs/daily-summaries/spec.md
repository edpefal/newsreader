## MODIFIED Requirements

### Requirement: Generación de resumen diario del inbox
El sistema SHALL generar, mediante una API de IA en la nube, un resumen de texto agrupado por fuente a partir del título y el contenido de los artículos del inbox (no leídos, no archivados) cuyo `publishedAt` corresponde a la fecha actual. Para cada artículo, el contenido usado SHALL ser el texto plano extraído de `contentHtml` cuando el artículo tiene contenido completo (no truncado); si `contentHtml` está truncado o vacío, SHALL usarse `excerpt` como fallback. El texto generado por fuente SHALL tener una voz narrativa consistente (tono cercano y con personalidad, sin emojis, en español latinoamericano neutro con tuteo), aplicada por igual sin importar el tono original de cada fuente.

Además del texto combinado, el sistema SHALL persistir junto al `DailySummary` la agrupación por fuente usada para armar la solicitud a la API de IA (identificador y nombre de cada fuente, junto con los ids de los artículos de esa fuente incluidos ese día), sin alterar el prompt ni la solicitud enviada a la API de IA.

#### Scenario: Generar resumen con artículos disponibles
- **WHEN** el usuario toca "Crear resumen" y el inbox tiene al menos un artículo publicado hoy
- **THEN** el sistema agrupa esos artículos por fuente, genera un párrafo por cada fuente (prefijado con su nombre) invocando la API de IA, y al finalizar crea o actualiza el `DailySummary` del día de hoy con el texto combinado

#### Scenario: Artículo con contenido completo usa el texto extraído de contentHtml
- **WHEN** un artículo del inbox de hoy tiene `contentHtml` no truncado (mismo criterio que `FeedContentChecker.isTruncated`)
- **THEN** el sistema usa el texto plano extraído de `contentHtml` (sin tags HTML) como contenido de ese artículo en el resumen, sin límite de longitud

#### Scenario: Artículo con contenido truncado usa excerpt como fallback
- **WHEN** un artículo del inbox de hoy tiene `contentHtml` truncado o vacío (mismo criterio que `FeedContentChecker.isTruncated`)
- **THEN** el sistema usa `excerpt` como contenido de ese artículo en el resumen, igual que el comportamiento anterior

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

### Requirement: Detalle de un resumen
El sistema SHALL permitir ver el texto completo de un `DailySummary` al seleccionar su item en la lista. El texto SHALL presentarse dividido por fuente: el nombre de cada fuente (primera línea de cada bloque separado por línea en blanco) SHALL mostrarse en negrita, seguido del párrafo correspondiente.

Debajo de cada párrafo, cuando el `DailySummary` tiene agrupación por fuente persistida y el nombre de esa fuente coincide con el bloque parseado, el sistema SHALL ofrecer navegación a los artículos que generaron ese párrafo:
- Si la fuente aportó un único artículo ese día, SHALL mostrarse un link directo a su detalle.
- Si aportó más de uno, SHALL mostrarse un link por artículo (título truncado).
- Los artículos referenciados que ya no existan localmente (ej. su fuente fue eliminada después) SHALL omitirse sin afectar al resto de los links de ese bloque.

Cuando el `DailySummary` no tiene agrupación por fuente persistida (resúmenes generados antes de esta funcionalidad), o el nombre de un bloque no coincide con ninguna fuente de la agrupación persistida, el sistema SHALL mostrar igualmente el título en negrita, sin ningún link debajo de ese bloque.

#### Scenario: Ver detalle de un resumen
- **WHEN** el usuario toca un item de la lista de resúmenes
- **THEN** el sistema navega a una pantalla de detalle que muestra el texto completo, la fecha y la cantidad de artículos de ese resumen

#### Scenario: Título de cada bloque en negrita
- **WHEN** se muestra el detalle de un `DailySummary`
- **THEN** el nombre de cada fuente (primera línea de cada bloque separado por línea en blanco) se muestra con estilo en negrita, distinguible del resto del párrafo

#### Scenario: Un artículo por fuente muestra un link directo
- **WHEN** la agrupación persistida indica que una fuente aportó un único artículo ese día
- **THEN** debajo del párrafo de esa fuente se muestra un link que navega directo al detalle de ese artículo

#### Scenario: Varios artículos por fuente muestran una fila de links
- **WHEN** la agrupación persistida indica que una fuente aportó más de un artículo ese día
- **THEN** debajo del párrafo de esa fuente se muestra un link por artículo, cada uno con el título truncado, cada uno navegando al detalle del artículo correspondiente

#### Scenario: Resumen sin agrupación persistida no muestra links
- **WHEN** el `DailySummary` fue generado antes de esta funcionalidad (sin agrupación por fuente persistida)
- **THEN** el sistema muestra los títulos de fuente en negrita igual que cualquier otro resumen, sin ningún link debajo de los párrafos

#### Scenario: Artículo referenciado ya no existe localmente
- **WHEN** uno de los `articleIds` de la agrupación persistida ya no corresponde a ningún artículo local (fue eliminado en cascada al borrar su fuente)
- **THEN** el sistema omite el link de ese artículo puntual sin afectar los demás links del mismo bloque ni el resto de la pantalla
