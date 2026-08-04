## ADDED Requirements

### Requirement: El servidor extrae una imagen destacada de cada ítem del feed
El sistema SHALL intentar obtener una URL de imagen destacada para cada ítem de feed durante el fetch, probando las siguientes fuentes en orden hasta encontrar una: (1) imagen de tipo Media RSS del ítem, (2) enclosure del ítem cuyo tipo sea una imagen, (3) imagen de iTunes del ítem, (4) primera imagen embebida en el HTML del contenido del ítem. El sistema SHALL usar la primera fuente que produzca una URL válida y SHALL ignorar las fuentes de menor prioridad una vez encontrada una.

#### Scenario: Feed con imagen Media RSS
- **WHEN** un ítem del feed incluye una imagen Media RSS
- **THEN** el artículo creado usa esa imagen, sin evaluar enclosure, iTunes ni el HTML del contenido

#### Scenario: Feed sin Media RSS pero con enclosure de imagen
- **WHEN** un ítem del feed no incluye imagen Media RSS pero sí un enclosure cuyo tipo es una imagen
- **THEN** el artículo creado usa la imagen del enclosure

#### Scenario: Feed con imagen únicamente embebida en el HTML
- **WHEN** un ítem del feed no incluye imagen Media RSS, enclosure de imagen, ni imagen de iTunes, pero su contenido HTML incluye al menos una imagen
- **THEN** el artículo creado usa la primera imagen encontrada en ese HTML

### Requirement: Ausencia de imagen no es una condición de fallo
El sistema SHALL crear el artículo normalmente cuando ninguna de las fuentes de imagen produce una URL válida, sin registrar la fuente como fallida ni interrumpir el fetch de las demás fuentes.

#### Scenario: Feed sin ninguna imagen disponible
- **WHEN** un ítem del feed no tiene imagen Media RSS, enclosure de imagen, imagen de iTunes, ni imágenes embebidas en su HTML
- **THEN** el artículo se crea sin imagen asociada, y la sincronización de esa fuente se considera exitosa
