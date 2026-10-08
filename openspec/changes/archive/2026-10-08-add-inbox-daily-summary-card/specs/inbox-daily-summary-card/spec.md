## Purpose

Mostrar el resumen diario de hoy como una tarjeta temporal en la parte superior del Inbox, para que no pase desapercibido para quien nunca entra a la tab Resúmenes, y quitarla una vez que el usuario la atendió (abierta desde donde sea, o descartada).

## ADDED Requirements

### Requirement: Tarjeta del resumen diario de hoy en el Inbox
El Inbox SHALL mostrar una tarjeta destacada del `DailySummary` de hoy cuando ese resumen existe localmente y no ha sido descartado (no tiene `dismissed_at`). "Hoy" SHALL determinarse comparando la fecha local del dispositivo con la fecha del resumen convertida a hora local, de modo que funcione para cualquier offset horario (incluidos los husos al este de UTC); NO SHALL depender de la clave de almacenamiento del resumen. La tarjeta SHALL ser el primer elemento del scroll del Inbox, ubicada debajo del `AppBar` y del buscador, y SHALL desplazarse con la lista (no queda fija) y participar del pull-to-refresh. La tarjeta NO SHALL participar del filtro de búsqueda: SHALL mostrarse igual con el buscador vacío o con texto en él, y SHALL mostrarse aunque el Inbox no tenga artículos. Si no existe un resumen de hoy sin descartar, el Inbox SHALL mostrarse sin tarjeta.

#### Scenario: Existe un resumen de hoy sin descartar
- **WHEN** el usuario abre el Inbox y existe un `DailySummary` cuya fecha local es hoy y sin `dismissed_at`
- **THEN** el Inbox muestra la tarjeta como primer elemento del scroll, antes de los artículos

#### Scenario: Usuario al este de UTC
- **WHEN** un usuario con offset UTC+2 tiene un `DailySummary` de hoy cuya fecha almacenada es las 22:00 UTC del día anterior
- **THEN** el Inbox lo reconoce como el resumen de hoy y muestra la tarjeta

#### Scenario: La búsqueda no afecta la tarjeta
- **WHEN** el usuario escribe texto en el buscador del Inbox mientras la tarjeta es visible
- **THEN** la tarjeta sigue mostrándose y solo se filtra la lista de artículos

#### Scenario: Inbox sin artículos
- **WHEN** el Inbox no tiene artículos y existe un resumen de hoy sin descartar
- **THEN** la tarjeta se muestra junto al estado vacío, dentro del mismo scroll con pull-to-refresh

#### Scenario: No hay resumen de hoy
- **WHEN** el usuario abre el Inbox y no existe un `DailySummary` de hoy (por ejemplo, un usuario sin suscripción un día que no es lunes)
- **THEN** el Inbox no muestra ninguna tarjeta

#### Scenario: Un resumen de un día anterior no se muestra
- **WHEN** existe un `DailySummary` de un día anterior que el usuario nunca abrió ni descartó
- **THEN** el Inbox no lo muestra; solo permanece disponible en la tab Resúmenes

#### Scenario: Resumen que llega con la app abierta
- **WHEN** una sincronización trae el `DailySummary` de hoy mientras el usuario está en el Inbox
- **THEN** la tarjeta aparece en la parte superior del Inbox con una animación de entrada

### Requirement: La tarjeta refleja los cambios del resumen hechos fuera del Inbox
La tarjeta SHALL aparecer o desaparecer en respuesta a cualquier cambio del `DailySummary` de hoy en el almacenamiento local, sin requerir recargar el Inbox ni volver a sincronizar desde él: abrir el resumen desde la tab Resúmenes, un descarte traído por sincronización desde otro dispositivo, o la llegada del resumen del día.

#### Scenario: Abrir el resumen desde la tab Resúmenes
- **WHEN** el usuario abre el resumen de hoy desde la tab Resúmenes y vuelve a la tab Inbox
- **THEN** la tarjeta ya no se muestra

#### Scenario: Descarte traído por sincronización
- **WHEN** una sincronización trae un `dismissed_at` del resumen de hoy descartado en otro dispositivo
- **THEN** la tarjeta sale del Inbox sin que el usuario haga nada

### Requirement: Contenido y aspecto de la tarjeta
La tarjeta SHALL tener un relleno sólido con el color de acento de marca (con el color de texto de mayor contraste para cada tema, claro y oscuro), y SHALL mostrar un título que la identifique como el resumen de hoy, el conteo de artículos y las fuentes del resumen, hasta 3 avatares de las fuentes incluidas más un indicador `+N` cuando hay más, y un llamado a la acción para leerlo. Cuando el `DailySummary` no tiene agrupación por fuente (resúmenes anteriores a esa funcionalidad), la tarjeta SHALL mostrar solo el título y el conteo de artículos, sin avatares ni conteo de fuentes, y NO SHALL tratarlo como un error. Todo texto de la tarjeta SHALL estar disponible en inglés, español y francés.

#### Scenario: Resumen con agrupación por fuente
- **WHEN** la tarjeta se muestra para un `DailySummary` con agrupación por fuente de 5 fuentes
- **THEN** muestra el título, el conteo de artículos y de fuentes, 3 avatares y un `+2`

#### Scenario: Resumen sin agrupación por fuente
- **WHEN** la tarjeta se muestra para un `DailySummary` sin agrupación por fuente
- **THEN** muestra solo el título y el conteo de artículos, sin avatares y sin reportar un error

#### Scenario: Tema claro y oscuro
- **WHEN** la app cambia entre tema claro y oscuro
- **THEN** la tarjeta mantiene un contraste legible entre su relleno y su texto en ambos temas

### Requirement: Accesibilidad de la tarjeta
La tarjeta SHALL anunciarse a los lectores de pantalla como un único elemento con una etiqueta que incluya su título, el conteo de artículos y su acción. Como el gesto de swipe no es accesible para lectores de pantalla, la tarjeta SHALL exponer una acción semántica "Descartar" equivalente al swipe. El estado seleccionado SHALL anunciarse como seleccionado y NO SHALL depender solo del color.

#### Scenario: Descartar con un lector de pantalla
- **WHEN** un usuario de lector de pantalla activa la acción "Descartar" de la tarjeta
- **THEN** la tarjeta se descarta igual que con el swipe

### Requirement: Abrir el detalle del resumen de hoy lo descarta, venga de donde venga
Al mostrarse el detalle del `DailySummary` de hoy, desde la tarjeta del Inbox o desde la tab Resúmenes, y también al restaurar o abrir su ruta directamente, el sistema SHALL persistir `dismissed_at` en ese resumen si todavía no lo tiene (operación idempotente). El detalle de un resumen de un día anterior NO SHALL escribir `dismissed_at`. Al tocar la tarjeta, el detalle SHALL abrirse dentro del Inbox (pantalla completa por debajo de 840dp, panel derecho en el layout de dos paneles; ver capability `adaptive-master-detail`), y volver desde el detalle SHALL regresar al Inbox, no a la tab Resúmenes. Por debajo de 840dp la tarjeta SHALL salir del Inbox con una animación al abrirse.

#### Scenario: Abrir en un teléfono desde la tarjeta
- **WHEN** el usuario toca la tarjeta con un ancho menor a 840dp
- **THEN** se abre el detalle a pantalla completa, el resumen queda con `dismissed_at`, la tarjeta sale del Inbox, y al volver el usuario regresa al Inbox sin la tarjeta

#### Scenario: Abrir desde la tab Resúmenes
- **WHEN** el usuario abre el resumen de hoy desde la tab Resúmenes
- **THEN** el resumen queda con `dismissed_at` y la tarjeta ya no se muestra al volver al Inbox

#### Scenario: Abrir un resumen de un día anterior
- **WHEN** el usuario abre desde la tab Resúmenes el resumen de un día anterior
- **THEN** no se escribe `dismissed_at` en ese resumen

#### Scenario: Abrir la ruta del detalle directamente
- **WHEN** la ruta del detalle del resumen de hoy se restaura o se abre sin pasar por la tarjeta
- **THEN** el resumen queda con `dismissed_at` igualmente

#### Scenario: Abrir no cambia de tab
- **WHEN** el usuario abre el resumen desde la tarjeta
- **THEN** la tab activa sigue siendo Inbox

### Requirement: Descartar la tarjeta con swipe
El usuario SHALL poder descartar la tarjeta deslizándola de derecha a izquierda, sin abrir el resumen, con un fondo de swipe distinto del usado para marcar un artículo como leído. El descarte SHALL persistir `dismissed_at` en el `DailySummary` y SHALL quitar la tarjeta del Inbox con una animación. El descarte NO SHALL ofrecer una acción de deshacer. El resumen descartado SHALL seguir disponible en la tab Resúmenes.

#### Scenario: Descartar con swipe
- **WHEN** el usuario desliza la tarjeta de derecha a izquierda
- **THEN** la tarjeta sale del Inbox, el `DailySummary` queda con `dismissed_at`, y el resumen sigue listado en la tab Resúmenes

#### Scenario: Deslizar en la otra dirección
- **WHEN** el usuario desliza la tarjeta de izquierda a derecha
- **THEN** la tarjeta no se descarta

### Requirement: La tarjeta permanece visible y seleccionada mientras su detalle está abierto en dos paneles
En el layout de dos paneles, tras tocar la tarjeta, esta SHALL permanecer visible en la columna central, con un borde de 2px en el color de texto del tema y su llamado a la acción cambiado a "Abierto", mientras la ruta activa del panel derecho esté bajo la ruta del detalle de ese resumen (el resumen mismo o un artículo abierto desde él). SHALL salir con animación únicamente cuando el usuario vuelve al estado vacío del panel derecho o selecciona otro elemento del Inbox. `dismissed_at` SHALL persistirse al abrirse el detalle, no al cerrarlo. La selección SHALL conservarse al cruzar el umbral de 840dp (rotación o redimensionado) sin perder el progreso de scroll del detalle.

#### Scenario: Abrir en iPad
- **WHEN** el usuario toca la tarjeta en modo de dos paneles
- **THEN** el panel derecho muestra el detalle, la tarjeta sigue visible con borde y el CTA "Abierto", y el `DailySummary` ya tiene `dismissed_at`

#### Scenario: Abrir un artículo desde el resumen en iPad
- **WHEN** el usuario toca un artículo dentro del detalle del resumen abierto en el panel derecho
- **THEN** el panel derecho muestra el lector de ese artículo, la tarjeta sigue seleccionada, y volver desde el lector regresa al resumen

#### Scenario: Cerrar el detalle en iPad
- **WHEN** el usuario vuelve desde el detalle del resumen al estado vacío del panel derecho
- **THEN** la tarjeta sale de la columna central con animación

#### Scenario: Cruzar el umbral con el detalle abierto
- **WHEN** el usuario tiene el detalle abierto desde la tarjeta y la ventana cruza el umbral de 840dp
- **THEN** el detalle sigue abierto en el modo que corresponde al nuevo ancho, sin reiniciarse

### Requirement: El descarte se sincroniza entre dispositivos
El estado de descarte de un `DailySummary` SHALL sincronizarse con la nube (ver capability `cloud-sync`, incluido el push inmediato): un resumen abierto o descartado en un dispositivo SHALL dejar de mostrarse como tarjeta en los demás dispositivos del mismo usuario tras su siguiente sincronización.

#### Scenario: Descartado en otro dispositivo
- **WHEN** el usuario abre o descarta la tarjeta en el dispositivo A y luego el dispositivo B sincroniza
- **THEN** el dispositivo B ya no muestra la tarjeta de ese resumen

### Requirement: Los errores de la tarjeta se reportan sin PII
El sistema SHALL reportar al proveedor de observabilidad toda falla al cargar el resumen pendiente, al suscribirse a sus cambios, al persistir su descarte o al abrir un resumen que ya no existe localmente, sin cambiar el comportamiento visible para el usuario (ante una falla de carga el Inbox se muestra sin tarjeta y sigue funcionando). Ningún reporte ni evento SHALL incluir el contenido del resumen. La ausencia de agrupación por fuente NO SHALL reportarse.

#### Scenario: Falla al cargar el resumen pendiente
- **WHEN** ocurre una excepción al leer el resumen de hoy para la tarjeta
- **THEN** el Inbox se muestra normalmente sin tarjeta y la excepción se reporta al proveedor de observabilidad

#### Scenario: Falla al persistir el descarte
- **WHEN** ocurre una excepción al persistir `dismissed_at`
- **THEN** la navegación o el swipe no se bloquean y la excepción se reporta

#### Scenario: Abrir un resumen que ya no existe
- **WHEN** el usuario abre la ruta del detalle de un resumen que no existe localmente
- **THEN** el sistema muestra el estado de error de la pantalla y reporta un mensaje de advertencia al proveedor de observabilidad
