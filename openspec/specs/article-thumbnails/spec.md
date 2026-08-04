# Capability: Article Thumbnails

## Purpose

Mostrar una imagen destacada junto a cada artículo en las listas de la app (Inbox, Leídos, Favoritos, Fuente) cuando el feed de origen la provee, para facilitar el escaneo visual de la lista.

## Requirements

### Requirement: Thumbnail visible cuando el artículo tiene imagen
El sistema SHALL mostrar un thumbnail de la imagen del artículo en cada fila de lista de artículos (Inbox, Leídos, Favoritos, pantalla de detalle de Fuente) cuando el artículo tiene una imagen asociada.

#### Scenario: Artículo con imagen en el Inbox
- **WHEN** el usuario ve el Inbox y un artículo tiene imagen asociada
- **THEN** la fila de ese artículo muestra el thumbnail junto al título y el nombre de la fuente

#### Scenario: La misma fila se ve igual en las cuatro pantallas
- **WHEN** un artículo con imagen aparece en Inbox, Leídos, Favoritos o en la lista de artículos de una Fuente
- **THEN** el thumbnail se muestra de la misma forma en las cuatro pantallas

---

### Requirement: Sin imagen reservada cuando el artículo no tiene una
El sistema SHALL mostrar la fila del artículo sin espacio de imagen reservado cuando el artículo no tiene imagen asociada, en vez de mostrar un placeholder o espacio en blanco.

#### Scenario: Artículo sin imagen
- **WHEN** un artículo no tiene imagen asociada (el feed de origen no proveyó ninguna)
- **THEN** la fila de ese artículo se muestra sin thumbnail, ocupando el mismo layout que las filas tenían antes de esta funcionalidad

---

### Requirement: La imagen de un artículo no cambia después de creado
El sistema SHALL conservar la imagen asociada a un artículo tal como fue determinada cuando el artículo se creó. El sistema NO SHALL volver a intentar obtener o actualizar la imagen de artículos que ya existían antes de que esta funcionalidad estuviera disponible.

#### Scenario: Artículo sincronizado antes de esta funcionalidad
- **WHEN** un artículo fue sincronizado al dispositivo antes de que el sistema soportara imágenes destacadas
- **THEN** ese artículo se sigue mostrando sin thumbnail, sin que el sistema intente completarlo retroactivamente
