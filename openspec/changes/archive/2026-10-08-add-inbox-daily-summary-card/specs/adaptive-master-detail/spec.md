## ADDED Requirements

### Requirement: Detalle de un resumen abierto desde el Inbox
El sistema SHALL mantener una ruta de detalle de resumen dentro de la rama Inbox (`/summary/:id`), direccionable por URL y compatible con el botón de retroceder, con una ruta anidada para abrir un artículo desde ese resumen sin salir de la rama Inbox. En el layout de dos paneles, el panel derecho del Inbox SHALL mostrar el detalle de ese resumen (o el lector del artículo abierto desde él) cuando es la selección abierta; por debajo de 840dp SHALL abrirse a pantalla completa. Esta selección SHALL convivir con la de artículos del Inbox: abrir uno cierra el otro.

#### Scenario: Abrir el resumen desde la tarjeta en dos paneles
- **WHEN** el usuario toca la tarjeta del resumen en el Inbox con un ancho de 840dp o más
- **THEN** el panel derecho del Inbox muestra el detalle del resumen y el rail de navegación sigue en Inbox

#### Scenario: Abrir el resumen desde la tarjeta en pantalla completa
- **WHEN** el usuario toca la tarjeta del resumen en el Inbox con un ancho menor a 840dp
- **THEN** el detalle se empuja a pantalla completa y al volver el usuario está en el Inbox

#### Scenario: Abrir un artículo desde el resumen sigue en el Inbox
- **WHEN** el usuario toca un artículo dentro del detalle del resumen abierto desde el Inbox
- **THEN** el artículo se abre dentro de la rama Inbox y volver regresa al resumen

#### Scenario: Seleccionar un artículo reemplaza el resumen abierto
- **WHEN** el usuario tiene el resumen abierto en el panel derecho del Inbox y toca un artículo de la columna central
- **THEN** el panel derecho muestra ese artículo y la tarjeta del resumen sale de la columna central
