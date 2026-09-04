# Spec: Daily Summaries

## Purpose

Define cómo el sistema genera, almacena y presenta resúmenes diarios de los artículos del inbox usando una API de IA en la nube. Cada día tiene como máximo un resumen, generado una única vez por día (sin posibilidad de regeneración).

## Requirements

### Requirement: Generación de resumen diario del inbox
El sistema SHALL generar, mediante una API de IA en la nube, un resumen de texto agrupado por fuente a partir del título y el contenido de los artículos del inbox (no leídos, no archivados) cuyo `publishedAt` corresponde a la fecha actual. Para cada artículo, el contenido usado SHALL ser el texto plano extraído de `contentHtml` cuando el artículo tiene contenido completo (no truncado); si `contentHtml` está truncado o vacío, SHALL usarse `excerpt` como fallback. El texto generado por fuente SHALL tener una voz narrativa consistente (tono cercano y con personalidad, sin emojis), aplicada por igual sin importar el tono original de cada fuente, y SHALL generarse en el idioma correspondiente al locale activo de la app en el dispositivo del usuario, de entre los idiomas que `AppLocalizations` soporta (inglés, español, francés). Si el locale activo no está entre los soportados, o no se pudo determinar, el sistema SHALL usar inglés como default.

Además del texto combinado, el sistema SHALL persistir junto al `DailySummary` la agrupación por fuente usada para armar la solicitud a la API de IA (identificador y nombre de cada fuente, junto con los ids de los artículos de esa fuente incluidos ese día), sin alterar el prompt ni la solicitud enviada a la API de IA.

La solicitud a la API de IA SHALL autenticarse con el access token de la sesión activa del usuario. El backend SHALL rechazar con un error de autenticación cualquier solicitud cuyo token no corresponda a una sesión de usuario autenticada (incluyendo solicitudes hechas con una key pública/anónima en vez de una sesión real), sin invocar a la API de IA en ese caso.

Generar un resumen SHALL requerir, alternativamente: (a) una suscripción activa (ver capability `subscription-entitlements`), o (b) cupo disponible del límite semanal gratis (ver capability `ai-usage-budget`, requirement "Límite semanal gratis de resumen diario"). El sistema SHALL verificar esto en el siguiente orden, tanto en la UI como en el backend: si hay suscripción activa, generar sin consultar ni descontar el cupo gratis; si no hay suscripción activa pero hay cupo gratis semanal disponible, generar y descontar 1 unidad de ese cupo; si no se cumple ninguna de las dos, la UI SHALL mostrar el paywall en vez de disparar la generación, y el backend SHALL rechazar la solicitud sin invocar a la API de IA. Si el usuario cierra el paywall sin completar la compra, el sistema NO SHALL disparar la generación: la UI SHALL volver a verificar que la suscripción esté efectivamente activa en el momento posterior al cierre del paywall, sin confiar únicamente en que el proveedor de paywall haya invocado el callback de "compra completada".

La generación SHALL además estar limitada a una única generación exitosa por día de servidor por usuario, independiente del presupuesto diario de `article-summaries` en `ai-usage-budget` (que no aplica a esta capability) y también independiente del límite semanal gratis propio de esta capability: si ya existe un `DailySummary` para el día de hoy de ese usuario, el backend SHALL rechazar la solicitud sin invocar a la API de IA y sin descontar el cupo gratis semanal (haya o no suscripción activa), y el sistema SHALL mostrar un estado de error distinguible de los demás (indicando que el resumen de hoy ya fue generado, no un error de red, de suscripción, ni de cupo gratis agotado).

Un intento de generación que falle por no tener artículos de hoy en el inbox, o por ya existir un resumen de hoy, NO SHALL descontar el cupo gratis semanal — el descuento SHALL ocurrir únicamente cuando el backend efectivamente invoca la API de IA y persiste un `DailySummary` exitosamente.

#### Scenario: Generar resumen con artículos disponibles
- **WHEN** el usuario con suscripción activa toca "Crear resumen", el inbox tiene al menos un artículo publicado hoy, y todavía no generó ningún resumen hoy
- **THEN** el sistema agrupa esos artículos por fuente, genera un párrafo por cada fuente (prefijado con su nombre) invocando la API de IA, y al finalizar crea el `DailySummary` del día de hoy con el texto combinado

#### Scenario: Usuario sin suscripción y sin cupo gratis ve el paywall al intentar generar
- **WHEN** el usuario sin suscripción activa y sin cupo gratis semanal disponible toca "Crear resumen"
- **THEN** el sistema muestra el paywall de Superwall en vez de disparar la generación

#### Scenario: Usuario sin suscripción pero con cupo gratis genera sin ver el paywall
- **WHEN** el usuario sin suscripción activa, con cupo gratis semanal disponible, el inbox con al menos un artículo de hoy, y sin resumen generado hoy, toca "Crear resumen"
- **THEN** el sistema genera el resumen igual que con suscripción activa, sin mostrar el paywall, y descuenta 1 unidad del cupo gratis semanal

#### Scenario: Backend rechaza la generación sin suscripción activa ni cupo gratis
- **WHEN** `summarize-articles` recibe una solicitud de un usuario autenticado cuya suscripción no está activa en la tabla de entitlements y cuyo cupo gratis semanal ya está agotado
- **THEN** el backend responde con un error de suscripción requerida y no invoca a la API de IA, y el sistema muestra un estado de error específico que indica ese motivo, distinto del estado de error genérico de falla de generación

#### Scenario: Cerrar el paywall sin comprar no dispara la generación
- **WHEN** el usuario sin suscripción activa y sin cupo gratis toca "Crear resumen", se muestra el paywall, y el usuario lo cierra sin completar ninguna compra
- **THEN** el sistema no dispara la generación del resumen ni envía ninguna solicitud al backend

#### Scenario: Completar la compra desde el paywall sí dispara la generación
- **WHEN** el usuario sin suscripción activa toca "Crear resumen", se muestra el paywall, y el usuario completa la compra
- **THEN** el sistema, con la suscripción ya activa, dispara la generación del resumen automáticamente a continuación

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
- **THEN** el párrafo resultante usa la misma voz narrativa con personalidad (sin emojis) y en el mismo idioma para todas las fuentes de ese resumen, no un tono ni idioma adaptado al estilo de esa fuente en particular

#### Scenario: El resumen se genera en el idioma activo de la app
- **WHEN** el usuario tiene la app en un locale soportado (inglés, español o francés) y genera el resumen diario
- **THEN** el texto del resumen se genera en ese mismo idioma, para todas las fuentes incluidas

#### Scenario: Locale no soportado o indeterminado cae a inglés
- **WHEN** el locale activo del usuario no es ninguno de los soportados por `AppLocalizations`, o el backend no puede determinarlo a partir de la solicitud
- **THEN** el sistema genera el resumen en inglés como default seguro

#### Scenario: Botón deshabilitado sin artículos de hoy
- **WHEN** el inbox no tiene artículos con `publishedAt` de la fecha actual
- **THEN** el botón "Crear resumen" SHALL estar deshabilitado y no SHALL invocarse la API de IA

#### Scenario: Falla la generación del resumen
- **WHEN** la llamada a la API de IA falla (sin red, error del backend, respuesta inválida, etc.)
- **THEN** el sistema SHALL mostrar un estado de error distinguible del estado "sin artículos", permitiendo reintentar

#### Scenario: Se persiste la agrupación por fuente junto al resumen
- **WHEN** el sistema genera exitosamente un `DailySummary`
- **THEN** además del texto combinado, persiste para cada fuente incluida ese día su identificador, nombre, y la lista de ids de los artículos de esa fuente usados en el resumen

#### Scenario: Rechazo por resumen de hoy ya generado
- **WHEN** el usuario intenta generar un resumen y ya existe un `DailySummary` para el día de hoy de ese usuario
- **THEN** el backend rechaza la solicitud sin invocar a la API de IA, y el sistema muestra un estado de error que indica específicamente que el resumen de hoy ya fue generado, distinto del estado de error genérico de falla de generación

#### Scenario: Rechazo por resumen de hoy ya generado no descuenta el cupo gratis
- **WHEN** el usuario sin suscripción activa, con cupo gratis semanal disponible, ya generó exitosamente un resumen hoy y vuelve a tocar "Crear resumen"
- **THEN** el backend rechaza la solicitud sin invocar a la API de IA y sin descontar el cupo gratis semanal, y el sistema muestra el estado de "resumen de hoy ya generado"

#### Scenario: Falta de artículos no descuenta el cupo gratis
- **WHEN** el usuario sin suscripción activa, con cupo gratis semanal disponible, intenta generar sin tener artículos de hoy en el inbox
- **THEN** el sistema no envía la solicitud al backend (botón deshabilitado) y el cupo gratis semanal permanece sin cambios

### Requirement: Indicador de cupo gratis antes de generar
Mientras el usuario no tenga suscripción activa, el sistema SHALL mostrar cuánto cupo gratis semanal le resta antes de generar, y SHALL mostrar un mensaje distinguible cuando ese cupo ya está agotado, en vez de mostrar directamente el paywall sin contexto.

#### Scenario: Cupo gratis disponible
- **WHEN** el usuario sin suscripción activa abre la pantalla de resúmenes y todavía tiene cupo gratis semanal disponible
- **THEN** el sistema muestra un indicador de que le queda cupo gratis disponible para esta semana

#### Scenario: Cupo gratis agotado
- **WHEN** el usuario sin suscripción activa abre la pantalla de resúmenes y ya agotó su cupo gratis semanal
- **THEN** el sistema muestra un mensaje indicando que el cupo gratis de esta semana ya se usó y que se recarga la próxima semana calendario, con la opción de suscribirse

### Requirement: Un único resumen por día, sin regeneración
El sistema SHALL mantener como máximo un `DailySummary` por fecha, y SHALL permitir como máximo una generación exitosa por fecha por usuario. Una vez generado el resumen de un día, ese `DailySummary` SHALL permanecer sin cambios hasta que el usuario elimine su fuente en cascada (ver capability `source-management`) — no existe ninguna acción de usuario que lo modifique o regenere ese mismo día.

#### Scenario: Nuevo día crea un nuevo resumen
- **WHEN** el usuario genera un resumen en una fecha distinta a la de cualquier `DailySummary` existente
- **THEN** el sistema crea un nuevo `DailySummary` para esa fecha, dejando intactos los resúmenes de días anteriores

#### Scenario: Segundo intento el mismo día no modifica el resumen existente
- **WHEN** ya existe un `DailySummary` para la fecha de hoy y el usuario intenta generar de nuevo ese mismo día (server day)
- **THEN** el sistema rechaza el intento sin invocar la API de IA ni modificar el `DailySummary` existente de hoy

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

### Requirement: Indicador de resumen ya generado hoy
El sistema SHALL mostrar en la pantalla de Resúmenes si el resumen de hoy ya fue generado o no, y SHALL deshabilitar el botón de generar cuando ya existe un `DailySummary` para el día de hoy de ese usuario, hasta el cambio de día de servidor.

#### Scenario: Indicador antes de generar
- **WHEN** el usuario entra a la pantalla de Resúmenes y todavía no generó el resumen de hoy
- **THEN** el sistema muestra que el resumen de hoy está disponible para generar (si además hay artículos de hoy) y el botón "Crear resumen" está habilitado

#### Scenario: Indicador después de generar
- **WHEN** el usuario entra a la pantalla de Resúmenes y ya generó el resumen de hoy
- **THEN** el sistema muestra que ya se usó el resumen del día, y el botón de generar SHALL estar deshabilitado hasta el día siguiente

### Requirement: El contenido de los artículos del día enviado a la API de IA está delimitado de la instrucción del sistema
El sistema SHALL enviar el contenido de cada artículo incluido en el resumen diario a la API de IA envuelto en un delimitador explícito que lo distinga de la instrucción del sistema, junto con una indicación de que ese contenido delimitado se trata siempre como texto a resumir y nunca como una instrucción a seguir, sin importar lo que ese contenido diga.

#### Scenario: Uno de los artículos del día incluye texto que simula una instrucción
- **WHEN** el contenido de alguno de los artículos incluidos en el resumen diario intenta darle una instrucción distinta al modelo (por ejemplo, pedirle que ignore las instrucciones anteriores o cambie de tono/idioma)
- **THEN** el sistema igual envía ese texto delimitado como contenido a resumir, sin que dejen de aplicarse las instrucciones de tono, idioma y formato ya definidas para el resumen diario
