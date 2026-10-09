## MODIFIED Requirements

### Requirement: Contenido y aspecto de la tarjeta
La tarjeta SHALL tener un relleno sólido con el color de acento de marca (con el color de texto de mayor contraste para cada tema, claro y oscuro) y esquinas con radio 14, y SHALL mostrar un título que la identifique como el resumen de hoy, precedido de un ícono decorativo de destello (IA) que no se anuncia a los lectores de pantalla, el conteo de artículos y las fuentes del resumen, hasta 3 avatares de las fuentes incluidas más un indicador `+N` cuando hay más, y un llamado a la acción para leerlo. Cada avatar SHALL ser circular y mostrar el ícono (`iconUrl`) de la fuente correspondiente al `sourceId` de la agrupación persistida, con un anillo del color del relleno de la tarjeta; si la fuente ya no existe localmente, no tiene ícono, o el ícono no carga, el avatar SHALL mostrar la inicial del `sourceName` guardado sobre un círculo translúcido, sin error ni espacio vacío. Cuando el `DailySummary` no tiene agrupación por fuente (resúmenes anteriores a esa funcionalidad), la tarjeta SHALL mostrar solo el título y el conteo de artículos, sin avatares ni conteo de fuentes, y NO SHALL tratarlo como un error. Todo texto de la tarjeta SHALL estar disponible en inglés, español y francés.

#### Scenario: Resumen con agrupación por fuente
- **WHEN** la tarjeta se muestra para un `DailySummary` con agrupación por fuente de 5 fuentes
- **THEN** muestra el ícono de destello y el título, el conteo de artículos y de fuentes, 3 avatares y un `+2`

#### Scenario: Avatares con el ícono real de cada fuente
- **WHEN** las fuentes de los 3 primeros bloques existen localmente y tienen `iconUrl`
- **THEN** cada avatar muestra el ícono de su fuente, recortado en círculo y con un anillo del color del relleno de la tarjeta

#### Scenario: Fuente sin ícono o eliminada
- **WHEN** la fuente de un avatar ya no existe localmente, no tiene `iconUrl`, o su imagen falla al cargar
- **THEN** ese avatar muestra la inicial de su `sourceName` guardado sobre un círculo translúcido, y los demás avatares no se ven afectados

#### Scenario: Resumen sin agrupación por fuente
- **WHEN** la tarjeta se muestra para un `DailySummary` sin agrupación por fuente
- **THEN** muestra solo el título (con su ícono de destello) y el conteo de artículos, sin avatares y sin reportar un error

#### Scenario: Tema claro y oscuro
- **WHEN** la app cambia entre tema claro y oscuro
- **THEN** la tarjeta mantiene un contraste legible entre su relleno y su texto en ambos temas

#### Scenario: El ícono de destello no se anuncia
- **WHEN** un lector de pantalla recorre la tarjeta
- **THEN** la tarjeta se anuncia como un único elemento con la misma etiqueta de antes (título, conteo y acción), sin mencionar el ícono de destello
