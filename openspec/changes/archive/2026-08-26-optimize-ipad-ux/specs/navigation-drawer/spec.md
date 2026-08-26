## MODIFIED Requirements

### Requirement: Indicador visual del destino seleccionado
El sistema SHALL distinguir el destino de navegación actualmente seleccionado con un estilo visualmente sutil (fondo claro, texto/ícono en un tono oscuro de contraste), sin que el indicador domine visualmente el resto de la lista de destinos. Este requisito aplica únicamente cuando el `NavigationDrawer` está visible, es decir, cuando el ancho de la ventana es menor a 840dp (ver capability `adaptive-navigation-rail`).

#### Scenario: Usuario navega a un destino distinto
- **WHEN** el usuario selecciona un destino distinto en el `NavigationDrawer`, con el ancho de la ventana menor a 840dp
- **THEN** el indicador de selección se mueve al nuevo destino con el mismo estilo sutil, sin usar un color que contraste fuertemente con el fondo general del drawer

### Requirement: Contador de no leídos legible con números grandes
El sistema SHALL mostrar el contador de artículos no leídos del Inbox en el `NavigationDrawer` de forma que el texto nunca se desborde de su contenedor visual, incluso cuando el conteo es un número de varios dígitos, y sin que el badge se superponga visualmente sobre el ícono ni sobre el texto de la etiqueta del destino Inbox. Este requisito aplica únicamente cuando el `NavigationDrawer` está visible (ancho de ventana menor a 840dp); en anchos mayores el contador se muestra en el `NavigationRail` según la capability `adaptive-navigation-rail`.

#### Scenario: Conteo de no leídos supera las tres cifras
- **WHEN** el conteo de artículos no leídos del Inbox es mayor a 999 y el `NavigationDrawer` está visible
- **THEN** el sistema muestra el contador con un formato abreviado (ej. "999+") en vez del número exacto, sin que el texto se desborde del indicador

#### Scenario: Conteo de no leídos de una o dos cifras
- **WHEN** el conteo de artículos no leídos del Inbox es 999 o menos y el `NavigationDrawer` está visible
- **THEN** el sistema muestra el número exacto dentro del indicador, sin desbordarlo

#### Scenario: Badge no se superpone al ícono ni al texto del destino Inbox
- **WHEN** el conteo de artículos no leídos del Inbox es mayor a 0, en cualquier estado de selección del destino (seleccionado o no seleccionado), y el `NavigationDrawer` está visible
- **THEN** el badge se muestra a la derecha del texto de la etiqueta "Inbox", separado tanto del ícono como del texto, sin cubrir ni superponerse visualmente a ninguno de los dos

### Requirement: Separadores de sección con margen respecto a los bordes
Los separadores visuales entre secciones del `NavigationDrawer` (ej. entre los destinos de navegación y las acciones de cuenta) SHALL tener un margen horizontal respecto a los bordes de la pantalla, alineado con el padding del resto del contenido del drawer, en vez de extenderse de borde a borde. El `NavigationDrawer` ya no incluye la acción "Cerrar sesión" (movida a la pantalla de Ajustes, ver capability `adaptive-navigation-rail`), por lo que este requisito aplica a los separadores restantes entre las secciones vigentes del drawer.

#### Scenario: Separador entre secciones del drawer
- **WHEN** se muestra un separador entre dos secciones del `NavigationDrawer`
- **THEN** el separador no toca los bordes izquierdo y derecho de la pantalla
