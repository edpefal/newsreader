# Spec: Daily Summaries

## Purpose

Define cómo el sistema genera, almacena y presenta resúmenes diarios de los artículos del inbox usando una API de IA en la nube. Cada día tiene como máximo un resumen, generado una única vez por día (sin posibilidad de regeneración).
## Requirements
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

### Requirement: Un único resumen por día, sin regeneración
El sistema SHALL mantener como máximo un `DailySummary` por fecha local por usuario, y SHALL permitir como máximo una generación exitosa por fecha local por usuario. Una vez generado el resumen de un día, ese `DailySummary` SHALL permanecer sin cambios hasta que el usuario elimine su fuente en cascada (ver capability `source-management`) — no existe ninguna acción, automática o de usuario, que lo modifique o regenere ese mismo día.

#### Scenario: Nuevo día crea un nuevo resumen
- **WHEN** el sistema genera un resumen para una fecha local distinta a la de cualquier `DailySummary` existente de ese usuario
- **THEN** el sistema crea un nuevo `DailySummary` para esa fecha, dejando intactos los resúmenes de días anteriores

#### Scenario: Un segundo intento el mismo día local no modifica el resumen existente
- **WHEN** ya existe un `DailySummary` para la fecha local de hoy de un usuario, y el sistema vuelve a evaluar a ese usuario en una corrida posterior el mismo día
- **THEN** el sistema no invoca la API de IA ni modifica el `DailySummary` existente de hoy

### Requirement: Listado de resúmenes diarios
El sistema SHALL mostrar una pantalla con la lista de todos los `DailySummary` existentes, ordenados de más reciente a más antiguo, cada uno mostrando la fecha y la cantidad de artículos resumidos.

#### Scenario: Lista vacía en primer ingreso
- **WHEN** el usuario entra a la pantalla de Resúmenes y no existe ningún `DailySummary`
- **THEN** el sistema muestra únicamente el botón para crear el resumen de hoy, sin items en la lista

#### Scenario: Lista con resúmenes existentes
- **WHEN** existen uno o más `DailySummary`
- **THEN** el sistema los lista ordenados por fecha descendente

### Requirement: Detalle de un resumen
El sistema SHALL permitir ver el texto completo de un `DailySummary` al seleccionar su item en la lista. El texto SHALL presentarse dividido por fuente: el nombre de cada fuente (primera línea de cada bloque separado por línea en blanco) SHALL mostrarse en negrita, seguido del párrafo correspondiente.

Si la primera línea de un bloque lleva como prefijo una etiqueta de fuente (`Fuente:` en español, `Source:` en inglés o `Source :` en francés, sin distinguir mayúsculas de minúsculas, con o sin espacios alrededor de los dos puntos), el sistema SHALL ignorar esa etiqueta tanto al mostrar el nombre de la fuente en negrita como al emparejar el bloque con la agrupación por fuente persistida: el nombre mostrado y el usado para el emparejamiento SHALL ser el que queda después de quitar la etiqueta y los espacios sobrantes. Este requisito aplica a cualquier `DailySummary`, incluidos los ya guardados antes de este cambio.

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

#### Scenario: Bloque con etiqueta "Fuente:" se empareja y muestra sin la etiqueta
- **WHEN** el texto de un `DailySummary` ya guardado empieza un bloque con `Fuente: TechCrunch` y la agrupación persistida tiene una fuente llamada `TechCrunch` con 2 artículos
- **THEN** el sistema muestra `TechCrunch` en negrita (sin la etiqueta) y debajo del párrafo muestra un link por cada uno de esos 2 artículos

#### Scenario: Etiqueta en otro idioma o con espacio antes de los dos puntos
- **WHEN** el primer renglón de un bloque es `Source: Stratechery` o `Source : Stratechery`, o `fuente: Stratechery` en minúsculas
- **THEN** el sistema se comporta igual que en el escenario anterior: ignora la etiqueta y empareja por el nombre `Stratechery`

#### Scenario: Una fuente cuyo nombre contiene dos puntos no se altera
- **WHEN** el primer renglón de un bloque es `Reuters: World News` y esa es exactamente la fuente persistida (no empieza con `Fuente`/`Source`)
- **THEN** el sistema NO quita nada de ese renglón, lo muestra completo y lo empareja por el nombre completo

### Requirement: El contenido de los artículos del día enviado a la API de IA está delimitado de la instrucción del sistema
El sistema SHALL enviar el contenido de cada artículo incluido en el resumen diario a la API de IA envuelto en un delimitador explícito que lo distinga de la instrucción del sistema, junto con una indicación de que ese contenido delimitado se trata siempre como texto a resumir y nunca como una instrucción a seguir, sin importar lo que ese contenido diga.

#### Scenario: Uno de los artículos del día incluye texto que simula una instrucción
- **WHEN** el contenido de alguno de los artículos incluidos en el resumen diario intenta darle una instrucción distinta al modelo (por ejemplo, pedirle que ignore las instrucciones anteriores o cambie de tono/idioma)
- **THEN** el sistema igual envía ese texto delimitado como contenido a resumir, sin que dejen de aplicarse las instrucciones de tono, idioma y formato ya definidas para el resumen diario

### Requirement: La agrupación por fuente sobrevive un ciclo de sincronización
La agrupación por fuente (`sourceBlocks`, con identificador y nombre de cada fuente y los ids de sus artículos) que el sistema persiste junto a un `DailySummary` recién generado SHALL seguir presente en el registro local después de que ese resumen participe en un ciclo de sincronización con la nube (subida y bajada), sin importar cuán pronto ocurra ese ciclo después de la generación.

#### Scenario: sourceBlocks sobrevive a una sincronización inmediatamente después de generar
- **WHEN** el sistema genera exitosamente un `DailySummary` con su agrupación por fuente, y a continuación corre un ciclo de sincronización (por ejemplo al abrir o refrescar el inbox)
- **THEN** el registro local de ese `DailySummary` conserva la misma agrupación por fuente (mismos ids de fuente, nombres, e ids de artículos) que tenía antes de sincronizar

#### Scenario: Un resumen bajado de la nube sin agrupación por fuente no borra la agrupación local existente
- **WHEN** el sistema baja de la nube un registro de `daily_summaries` que no trae agrupación por fuente para un resumen que localmente ya tiene una
- **THEN** el sistema SHALL preservar la agrupación por fuente local en vez de sobrescribirla con un valor vacío

### Requirement: El encabezado de cada fuente en el texto generado es solo el nombre de la fuente
El sistema SHALL persistir en `DailySummary.content` cada bloque de fuente con su primera línea igual al nombre de la fuente, sin ninguna etiqueta delante (`Fuente:`, `Source:`, etc.), incluso si la API de IA devolvió esa etiqueta en su respuesta: el servidor SHALL quitarla de la primera línea de cada bloque antes de guardar el resumen. La quita SHALL aplicarse únicamente cuando, una vez quitada la etiqueta, el resto de la línea coincide con el nombre de una de las fuentes de la agrupación por fuente de ese resumen, y nunca a texto dentro del párrafo, y SHALL dejar el resto del contenido sin cambios. La solicitud enviada a la API de IA (qué artículos y qué contenido se envían, y cómo se rotulan) SHALL permanecer sin cambios.

#### Scenario: La API de IA devuelve el encabezado con etiqueta
- **WHEN** la API de IA responde con un bloque cuya primera línea es `Fuente: TechCrunch`
- **THEN** el `DailySummary` se guarda con esa primera línea como `TechCrunch`, y el párrafo del bloque queda intacto

#### Scenario: La API de IA devuelve el encabezado sin etiqueta
- **WHEN** la API de IA responde con un bloque cuya primera línea es `TechCrunch`
- **THEN** el `DailySummary` se guarda exactamente como llegó, sin ninguna modificación

#### Scenario: La palabra "Fuente" dentro del párrafo no se toca
- **WHEN** el párrafo de un bloque contiene la frase `Fuente: según el reporte` en una línea que no es la primera del bloque
- **THEN** el sistema conserva esa línea tal cual en el `DailySummary` guardado

#### Scenario: Una primera línea con dos puntos que no es una etiqueta de fuente no se altera
- **WHEN** la API de IA responde con un bloque cuya primera línea es `Fuente: desconocida`, y `desconocida` no es el nombre de ninguna fuente de la agrupación de ese resumen
- **THEN** el sistema guarda esa línea sin modificarla

#### Scenario: El texto limpio sigue emparejando con la agrupación persistida
- **WHEN** se genera un resumen nuevo y la API de IA copió la etiqueta en alguno de los bloques
- **THEN** la primera línea de cada bloque guardado coincide exactamente con el `sourceName` de su entrada en la agrupación por fuente persistida

