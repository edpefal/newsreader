# Capability: Adaptive Master-Detail

## Purpose

Define el layout de dos paneles (lista fija + detalle) que reemplaza el push de pantalla completa en las cinco tabs principales de la app cuando el ancho de la ventana es suficiente, junto con las reglas de qué se muestra en el panel derecho y cómo se preserva la selección del usuario.

---

## Requirements

### Requirement: Umbral de ancho para el layout de dos paneles
El sistema SHALL mostrar cada una de las cinco tabs (Inbox, Favoritos, Archivo, Fuentes, Resúmenes) como un layout de dos paneles (lista fija a la izquierda, detalle a la derecha) cuando el ancho disponible de la ventana sea de 840dp o más, y SHALL usar el comportamiento actual de push de pantalla completa cuando el ancho sea menor a 840dp. El push de pantalla completa SHALL reemplazar por completo el chrome del shell principal (el `AppBar` con logo/título/buscador y el `NavigationDrawer`), mostrando únicamente el `AppBar` y contenido propios de la pantalla de detalle empujada.

#### Scenario: Ventana ancha en cualquiera de las cinco tabs
- **WHEN** el ancho de la ventana es de 840dp o más y el usuario está en Inbox, Favoritos, Archivo, Fuentes o Resúmenes
- **THEN** el sistema muestra la lista de esa tab en un panel fijo a la izquierda y un panel de detalle a la derecha, ambos visibles simultáneamente

#### Scenario: Ventana angosta en cualquiera de las cinco tabs
- **WHEN** el ancho de la ventana es menor a 840dp
- **THEN** el sistema muestra solo la lista de la tab activa, y abrir un ítem reemplaza la lista con un push de pantalla completa, igual que el comportamiento actual

#### Scenario: Chrome del shell principal oculto durante el push de un detalle
- **WHEN** el ancho de la ventana es menor a 840dp y el usuario abre un artículo, una fuente o un resumen (push de pantalla completa)
- **THEN** el `AppBar` principal (logo, título de la tab, buscador) y el `NavigationDrawer` dejan de mostrarse, y solo se ve el `AppBar` y el contenido propios de la pantalla de detalle

#### Scenario: Chrome del shell principal reaparece al volver a la lista
- **WHEN** el usuario, con el ancho de la ventana menor a 840dp, cierra una pantalla de detalle abierta por push de pantalla completa (botón de volver)
- **THEN** el `AppBar` principal y el acceso al `NavigationDrawer` vuelven a mostrarse sobre la lista de la tab activa

### Requirement: Contenido del panel derecho en Inbox, Favoritos y Archivo
En el layout de dos paneles, el panel derecho de Inbox, Favoritos y Archivo SHALL mostrar el lector del artículo seleccionado, o un estado vacío indicando que no hay ningún artículo seleccionado cuando no se ha tocado ninguno todavía.

#### Scenario: Ninguna selección todavía
- **WHEN** el usuario entra a Inbox, Favoritos o Archivo en modo de dos paneles sin haber seleccionado ningún artículo
- **THEN** el panel derecho muestra un estado vacío invitando a seleccionar un artículo

#### Scenario: Usuario selecciona un artículo
- **WHEN** el usuario toca un artículo en la lista de Inbox, Favoritos o Archivo en modo de dos paneles
- **THEN** el panel derecho muestra el lector de ese artículo sin ocultar la lista

### Requirement: Contenido del panel derecho en Fuentes
En el layout de dos paneles de Fuentes, el panel derecho SHALL mostrar el detalle de la fuente seleccionada (o un estado vacío si no hay selección); al seleccionar un artículo de esa fuente, el panel derecho SHALL reemplazar el detalle de la fuente por el lector de ese artículo, ofreciendo una forma de volver al detalle de la fuente sin abandonar el layout de dos paneles.

#### Scenario: Usuario selecciona una fuente
- **WHEN** el usuario toca una fuente en la lista de Fuentes en modo de dos paneles
- **THEN** el panel derecho muestra el detalle de esa fuente, incluyendo su lista de artículos

#### Scenario: Usuario abre un artículo de la fuente seleccionada
- **WHEN** el usuario toca un artículo dentro del detalle de una fuente, en modo de dos paneles
- **THEN** el panel derecho reemplaza el detalle de la fuente por el lector de ese artículo, sin agregar una tercera columna ni ocultar la lista de fuentes

#### Scenario: Usuario vuelve del artículo al detalle de la fuente
- **WHEN** el usuario, con un artículo abierto en el panel derecho desde el flujo de Fuentes, activa la acción de volver dentro del panel
- **THEN** el panel derecho vuelve a mostrar el detalle de la fuente que estaba seleccionada, sin cerrar el layout de dos paneles ni cambiar la lista de fuentes

### Requirement: Contenido del panel derecho en Resúmenes
En el layout de dos paneles de Resúmenes, el panel derecho SHALL mostrar el detalle del resumen diario seleccionado, o un estado vacío cuando no hay ningún resumen seleccionado.

#### Scenario: Usuario selecciona un resumen diario
- **WHEN** el usuario toca un resumen en la lista de Resúmenes en modo de dos paneles
- **THEN** el panel derecho muestra el detalle de ese resumen diario

### Requirement: Las rutas de detalle siguen siendo direccionables
El sistema SHALL mantener las rutas `/article/:id`, `/sources/:id` y `/summaries/:date` como rutas reales de navegación, direccionables por URL y compatibles con el botón de retroceder, independientemente de si se renderizan a pantalla completa o dentro del panel derecho del layout de dos paneles.

#### Scenario: Deep link a un artículo con la ventana ancha
- **WHEN** la app se abre directamente en la ruta `/article/:id` con el ancho de ventana en modo de dos paneles
- **THEN** el sistema muestra la lista correspondiente a la izquierda y el artículo en el panel derecho, sin perder la capacidad de la ruta de resolverse por identificador

### Requirement: Persistencia de la selección al cruzar el umbral de ancho
El sistema SHALL preservar el ítem actualmente seleccionado (artículo, fuente o resumen) al cruzar el umbral de 840dp en cualquier dirección, incluyendo el progreso de scroll dentro del lector, sin requerir que el usuario vuelva a seleccionarlo.

#### Scenario: De ventana ancha a angosta con una selección activa
- **WHEN** el usuario tiene un ítem abierto en el panel derecho y el ancho de la ventana cruza por debajo de 840dp
- **THEN** el sistema muestra ese mismo ítem como push de pantalla completa, conservando su progreso de scroll, y el botón de retroceder regresa a la lista

#### Scenario: De ventana angosta a ancha con una selección activa
- **WHEN** el usuario tiene un ítem abierto a pantalla completa (modo push) y el ancho de la ventana cruza por encima de 840dp
- **THEN** el sistema acomoda ese mismo ítem en el panel derecho del layout de dos paneles, conservando su progreso de scroll, y la lista reaparece en el panel izquierdo

### Requirement: Selección independiente por tab
El sistema SHALL recordar la selección del panel derecho de forma independiente para cada una de las cinco tabs, de modo que cambiar de tab y volver restaure la selección que tenía esa tab antes de salir.

#### Scenario: Usuario cambia de tab y vuelve
- **WHEN** el usuario tiene un artículo seleccionado en Inbox, cambia a la tab de Favoritos, y luego vuelve a Inbox, todo en modo de dos paneles
- **THEN** el panel derecho de Inbox muestra el mismo artículo que tenía seleccionado antes de cambiar de tab

### Requirement: El artículo abierto del Inbox se resalta en la columna central en vez de desaparecer
En el layout de dos paneles, mientras un artículo del Inbox es la selección mostrada en el panel de detalle, el sistema SHALL mantenerlo visible en la columna central con un color de fondo distintivo (adecuado tanto en tema claro como oscuro), en lugar de quitarlo de la lista.

#### Scenario: Usuario toca un artículo no leído del Inbox
- **WHEN** el usuario toca un artículo en la columna central del Inbox en modo de dos paneles
- **THEN** el panel derecho muestra el lector de ese artículo y la fila de ese artículo en la columna central se resalta con un color de fondo distinto, sin desaparecer de la lista

#### Scenario: Artículo resaltado sigue visible tras sincronizar
- **WHEN** el artículo abierto en el panel derecho del Inbox está resaltado en la columna central y ocurre una sincronización (manual o en segundo plano)
- **THEN** el artículo resaltado permanece visible en la columna central mientras siga siendo la selección abierta

### Requirement: El artículo del Inbox solo se archiva de la columna central al cerrarse explícitamente
El sistema SHALL quitar de la columna central del Inbox (animando su salida, igual que hoy) al artículo que estaba resaltado únicamente cuando el usuario lo cierra explícitamente: activando la acción de volver del lector hacia el estado vacío del panel derecho, o seleccionando otro artículo de la columna central.

#### Scenario: Usuario vuelve con el botón de retroceder del lector
- **WHEN** el usuario, con un artículo resaltado y abierto en el panel derecho del Inbox, toca el botón de volver del lector
- **THEN** el panel derecho vuelve al estado vacío y el artículo que estaba resaltado se anima hacia afuera y desaparece de la columna central

#### Scenario: Usuario selecciona otro artículo de la columna central
- **WHEN** el usuario, con un artículo A resaltado y abierto en el panel derecho del Inbox, toca un artículo B distinto en la columna central
- **THEN** el panel derecho pasa a mostrar el lector del artículo B, el artículo A se anima hacia afuera y desaparece de la columna central, y el artículo B pasa a resaltarse

#### Scenario: Cambiar de tab y volver no cierra la selección
- **WHEN** el usuario, con un artículo resaltado y abierto en el panel derecho del Inbox, cambia a otra tab (Favoritos, Archivo, Fuentes o Resúmenes) y luego vuelve al Inbox
- **THEN** el artículo sigue resaltado en la columna central y sigue mostrado en el panel derecho, sin haberse archivado por el cambio de tab
