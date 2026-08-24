## Purpose

Garantiza una separación visual perceptible entre ítems consecutivos en las listas de artículos y de fuentes de la app, para que el usuario pueda distinguir con claridad dónde termina un ítem y empieza el siguiente al escanear la lista.

## Requirements

### Requirement: Separación vertical entre ítems de artículo
Las listas que muestran ítems de artículo (inbox, archivo, favoritos, detalle de fuente) SHALL renderizar un espacio vertical visible entre el borde inferior de un ítem de artículo y el borde superior del siguiente ítem (artículo o encabezado de fecha), mayor al que resulta del padding intrínseco por defecto de un `ListTile` sin modificar.

#### Scenario: Dos artículos consecutivos en el mismo día
- **WHEN** el inbox muestra dos artículos consecutivos publicados el mismo día (sin encabezado de fecha entre ellos)
- **THEN** existe un espacio vertical visible entre ambos ítems que permite distinguir claramente sus límites

#### Scenario: Espaciado consistente entre listas de artículos
- **WHEN** se comparan visualmente el inbox, el archivo, favoritos y el detalle de una fuente
- **THEN** el espacio vertical entre ítems consecutivos de artículo es el mismo en las cuatro listas

### Requirement: Separación vertical entre ítems de fuente
La lista de fuentes SHALL renderizar un espacio vertical visible entre el borde inferior de una fuente y el borde superior de la siguiente, mayor al que resulta del padding intrínseco por defecto de un `ListTile` sin modificar.

#### Scenario: Dos fuentes consecutivas
- **WHEN** la pantalla de fuentes muestra dos o más fuentes suscritas
- **THEN** existe un espacio vertical visible entre cada par de fuentes consecutivas

### Requirement: El espaciado no altera el contenido del ítem
Aumentar el espacio entre ítems SHALL preservar el contenido y layout interno de cada tile (thumbnail, título, subtítulo, ícono de fuente, indicador de no leído, trailing) sin recortarlo ni reflowearlo de forma no intencional.

#### Scenario: Título de dos líneas sigue truncándose igual
- **WHEN** un artículo con título largo se muestra en cualquiera de las listas afectadas
- **THEN** el título sigue truncándose a un máximo de 2 líneas con elipsis, igual que antes del cambio de espaciado
