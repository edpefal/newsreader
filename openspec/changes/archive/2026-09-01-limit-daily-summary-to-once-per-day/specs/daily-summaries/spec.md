## MODIFIED Requirements

### Requirement: Generación de resumen diario del inbox
El sistema SHALL generar, mediante una API de IA en la nube, un resumen de texto agrupado por fuente a partir del título y el contenido de los artículos del inbox (no leídos, no archivados) cuyo `publishedAt` corresponde a la fecha actual. Para cada artículo, el contenido usado SHALL ser el texto plano extraído de `contentHtml` cuando el artículo tiene contenido completo (no truncado); si `contentHtml` está truncado o vacío, SHALL usarse `excerpt` como fallback. El texto generado por fuente SHALL tener una voz narrativa consistente (tono cercano y con personalidad, sin emojis), aplicada por igual sin importar el tono original de cada fuente, y SHALL generarse en el idioma correspondiente al locale activo de la app en el dispositivo del usuario, de entre los idiomas que `AppLocalizations` soporta (inglés, español, francés). Si el locale activo no está entre los soportados, o no se pudo determinar, el sistema SHALL usar inglés como default.

Además del texto combinado, el sistema SHALL persistir junto al `DailySummary` la agrupación por fuente usada para armar la solicitud a la API de IA (identificador y nombre de cada fuente, junto con los ids de los artículos de esa fuente incluidos ese día), sin alterar el prompt ni la solicitud enviada a la API de IA.

La solicitud a la API de IA SHALL autenticarse con el access token de la sesión activa del usuario. El backend SHALL rechazar con un error de autenticación cualquier solicitud cuyo token no corresponda a una sesión de usuario autenticada (incluyendo solicitudes hechas con una key pública/anónima en vez de una sesión real), sin invocar a la API de IA en ese caso.

Generar un resumen SHALL requerir una suscripción activa (ver capability `subscription-entitlements`). El sistema SHALL verificar esto tanto en la UI (mostrando el paywall si no hay suscripción activa, en vez de disparar la generación) como en el backend (rechazando la solicitud sin invocar a la API de IA si el usuario autenticado no tiene una suscripción activa). Si el usuario cierra el paywall sin completar la compra, el sistema NO SHALL disparar la generación: la UI SHALL volver a verificar que la suscripción esté efectivamente activa en el momento posterior al cierre del paywall, sin confiar únicamente en que el proveedor de paywall haya invocado el callback de "compra completada".

La generación SHALL además estar limitada a una única generación exitosa por día de servidor por usuario, independiente del presupuesto de palabras de `ai-usage-budget` (que ya no aplica a esta capability): si ya existe un `DailySummary` para el día de hoy de ese usuario, el backend SHALL rechazar la solicitud sin invocar a la API de IA, y el sistema SHALL mostrar un estado de error distinguible de los demás (indicando que el resumen de hoy ya fue generado, no un error de red ni de suscripción).

#### Scenario: Generar resumen con artículos disponibles
- **WHEN** el usuario con suscripción activa toca "Crear resumen", el inbox tiene al menos un artículo publicado hoy, y todavía no generó ningún resumen hoy
- **THEN** el sistema agrupa esos artículos por fuente, genera un párrafo por cada fuente (prefijado con su nombre) invocando la API de IA, y al finalizar crea el `DailySummary` del día de hoy con el texto combinado

#### Scenario: Usuario sin suscripción activa ve el paywall al intentar generar
- **WHEN** el usuario sin suscripción activa toca "Crear resumen"
- **THEN** el sistema muestra el paywall de Superwall en vez de disparar la generación

#### Scenario: Backend rechaza la generación sin suscripción activa
- **WHEN** `summarize-articles` recibe una solicitud de un usuario autenticado cuya suscripción no está activa en la tabla de entitlements
- **THEN** el backend responde con un error de suscripción requerida y no invoca a la API de IA, y el sistema muestra un estado de error específico que indica ese motivo, distinto del estado de error genérico de falla de generación

#### Scenario: Cerrar el paywall sin comprar no dispara la generación
- **WHEN** el usuario sin suscripción activa toca "Crear resumen", se muestra el paywall, y el usuario lo cierra sin completar ninguna compra
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

### Requirement: Un único resumen por día, sin regeneración
El sistema SHALL mantener como máximo un `DailySummary` por fecha, y SHALL permitir como máximo una generación exitosa por fecha por usuario. Una vez generado el resumen de un día, ese `DailySummary` SHALL permanecer sin cambios hasta que el usuario elimine su fuente en cascada (ver capability `source-management`) — no existe ninguna acción de usuario que lo modifique o regenere ese mismo día.

#### Scenario: Nuevo día crea un nuevo resumen
- **WHEN** el usuario genera un resumen en una fecha distinta a la de cualquier `DailySummary` existente
- **THEN** el sistema crea un nuevo `DailySummary` para esa fecha, dejando intactos los resúmenes de días anteriores

#### Scenario: Segundo intento el mismo día no modifica el resumen existente
- **WHEN** ya existe un `DailySummary` para la fecha de hoy y el usuario intenta generar de nuevo ese mismo día (server day)
- **THEN** el sistema rechaza el intento sin invocar la API de IA ni modificar el `DailySummary` existente de hoy

## REMOVED Requirements

### Requirement: Medidor visible de consumo de IA
**Reason**: el resumen diario deja de estar limitado por el presupuesto compartido de palabras de `ai-usage-budget` — pasa a limitarse por "una generación por día", que no tiene un "consumo parcial" que mostrar en un medidor.
**Migration**: reemplazado por un indicador booleano simple ("resumen de hoy ya generado" / "todavía no"), capturado en el nuevo Requirement "Indicador de resumen ya generado hoy" de este mismo delta.

### Requirement: Confirmación antes de regenerar sin artículos nuevos
**Reason**: esta capability entera dependía de que existiera la acción de "Regenerar resumen de hoy", que se elimina junto con el límite de una generación por día — ya no hay ningún escenario en el que el usuario pueda intentar regenerar el resumen de hoy, con o sin artículos nuevos.
**Migration**: ninguna — no hay reemplazo, la funcionalidad de regenerar deja de existir.

## ADDED Requirements

### Requirement: Indicador de resumen ya generado hoy
El sistema SHALL mostrar en la pantalla de Resúmenes si el resumen de hoy ya fue generado o no, y SHALL deshabilitar el botón de generar cuando ya existe un `DailySummary` para el día de hoy de ese usuario, hasta el cambio de día de servidor.

#### Scenario: Indicador antes de generar
- **WHEN** el usuario entra a la pantalla de Resúmenes y todavía no generó el resumen de hoy
- **THEN** el sistema muestra que el resumen de hoy está disponible para generar (si además hay artículos de hoy) y el botón "Crear resumen" está habilitado

#### Scenario: Indicador después de generar
- **WHEN** el usuario entra a la pantalla de Resúmenes y ya generó el resumen de hoy
- **THEN** el sistema muestra que ya se usó el resumen del día, y el botón de generar SHALL estar deshabilitado hasta el día siguiente
