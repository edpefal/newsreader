## MODIFIED Requirements

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
