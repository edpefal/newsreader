# Capability: Navigation Drawer

## Purpose

Define el comportamiento visual y estructural del `NavigationDrawer` de la app: cómo se distingue el destino seleccionado, cómo se presenta el contador de no leídos, el layout de su header, y la consistencia entre íconos y labels de cada destino.

---

## Requirements

### Requirement: Indicador visual del destino seleccionado
El sistema SHALL distinguir el destino de navegación actualmente seleccionado con un estilo visualmente sutil (fondo claro, texto/ícono en un tono oscuro de contraste), sin que el indicador domine visualmente el resto de la lista de destinos.

#### Scenario: Usuario navega a un destino distinto
- **WHEN** el usuario selecciona un destino distinto en el `NavigationDrawer`
- **THEN** el indicador de selección se mueve al nuevo destino con el mismo estilo sutil, sin usar un color que contraste fuertemente con el fondo general del drawer

### Requirement: Contador de no leídos legible con números grandes
El sistema SHALL mostrar el contador de artículos no leídos del Inbox en el `NavigationDrawer` de forma que el texto nunca se desborde de su contenedor visual, incluso cuando el conteo es un número de varios dígitos.

#### Scenario: Conteo de no leídos supera las tres cifras
- **WHEN** el conteo de artículos no leídos del Inbox es mayor a 999
- **THEN** el sistema muestra el contador con un formato abreviado (ej. "999+") en vez del número exacto, sin que el texto se desborde del indicador

#### Scenario: Conteo de no leídos de una o dos cifras
- **WHEN** el conteo de artículos no leídos del Inbox es 999 o menos
- **THEN** el sistema muestra el número exacto dentro del indicador, sin desbordarlo

### Requirement: Layout compacto del header del drawer
El sistema SHALL ajustar la altura del header del `NavigationDrawer` al contenido que muestra, sin reservar espacio en blanco forzado adicional al necesario para ese contenido.

#### Scenario: Header del drawer con el contenido actual
- **WHEN** el usuario abre el `NavigationDrawer`
- **THEN** el header ocupa solo el espacio necesario para mostrar su contenido, sin un área vacía adicional debajo

### Requirement: Separadores de sección con margen respecto a los bordes
Los separadores visuales entre secciones del `NavigationDrawer` (ej. entre los destinos de navegación y las acciones de cuenta) SHALL tener un margen horizontal respecto a los bordes de la pantalla, alineado con el padding del resto del contenido del drawer, en vez de extenderse de borde a borde.

#### Scenario: Separador entre secciones del drawer
- **WHEN** se muestra un separador entre dos secciones del `NavigationDrawer`
- **THEN** el separador no toca los bordes izquierdo y derecho de la pantalla

### Requirement: Consistencia entre ícono y label de cada destino
Cada destino de navegación en el `NavigationDrawer` SHALL usar un ícono cuyo significado sea coherente con el texto de su label.

#### Scenario: Destino de artículos leídos
- **WHEN** se muestra el destino correspondiente a los artículos ya leídos (label "Leídos")
- **THEN** el ícono usado SHALL representar el concepto de "leído", no el de "archivado"
