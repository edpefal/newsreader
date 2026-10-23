## MODIFIED Requirements

### Requirement: Contenido del panel derecho en Resúmenes
En el layout de dos paneles de Resúmenes, el panel izquierdo SHALL mostrar el `DailySummary` más reciente (ver capability `daily-summaries`) y el panel derecho SHALL mostrar el lector del artículo abierto desde ese resumen, o un estado vacío ("elige un artículo") cuando no hay ningún artículo abierto. Por debajo de 840dp, el resumen SHALL ocupar toda la tab y el lector SHALL abrirse a pantalla completa. Cuando no existe ningún `DailySummary`, el panel izquierdo SHALL mostrar el estado vacío de la tab.

#### Scenario: Usuario abre un artículo desde el resumen en modo de dos paneles
- **WHEN** el usuario toca la fila de un artículo en el resumen mostrado en el panel izquierdo
- **THEN** el panel derecho muestra el lector de ese artículo y el resumen permanece visible a la izquierda

#### Scenario: Resumen sin artículo abierto en modo de dos paneles
- **WHEN** el usuario entra a la tab Resúmenes en modo de dos paneles y no ha abierto ningún artículo
- **THEN** el panel izquierdo muestra el resumen más reciente y el panel derecho muestra el estado vacío "elige un artículo"

#### Scenario: Artículo abierto al cruzar el umbral de ancho
- **WHEN** el usuario tiene un artículo abierto desde el resumen y el ancho de la ventana cruza el umbral de 840dp en cualquier dirección
- **THEN** el mismo artículo se conserva (a pantalla completa por debajo del umbral, en el panel derecho por encima) con su progreso de scroll

### Requirement: Las rutas de detalle siguen siendo direccionables
El sistema SHALL mantener las rutas `/article/:id`, `/sources/:id` y `/summaries/article/:articleId` como rutas reales de navegación, direccionables por URL y compatibles con el botón de retroceder, independientemente de si se renderizan a pantalla completa o dentro del panel derecho del layout de dos paneles.

#### Scenario: Deep link a un artículo con la ventana ancha
- **WHEN** la app se abre directamente en la ruta `/article/:id` con el ancho de ventana en modo de dos paneles
- **THEN** el sistema muestra la lista correspondiente a la izquierda y el artículo en el panel derecho, sin perder la capacidad de la ruta de resolverse por identificador

#### Scenario: La tab Resúmenes no tiene ruta de detalle por fecha
- **WHEN** la app se abre en `/summaries/{fecha}`
- **THEN** el sistema no resuelve esa ruta como el detalle de un resumen; el único detalle de la tab es el lector en `/summaries/article/:articleId`
