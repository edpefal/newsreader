## Purpose

Define el tamaño y estilo de tipografía con el que se renderiza el texto del cuerpo de un artículo dentro del lector, para asegurar una lectura cómoda.

## Requirements

### Requirement: Tamaño de fuente legible en el cuerpo del artículo
El lector SHALL renderizar el texto del cuerpo de un artículo (contenido HTML del artículo) con un tamaño de fuente mayor al usado en las listas de artículos (inbox, archivo, favoritos), de forma que sea cómodo de leer en artículos largos.

#### Scenario: Usuario abre un artículo con contenido HTML
- **WHEN** el usuario abre un artículo desde el inbox, archivo o favoritos y su contenido HTML no está truncado
- **THEN** el texto del cuerpo del artículo se muestra con el tamaño de fuente aumentado del lector

#### Scenario: El tamaño de fuente de las listas no cambia
- **WHEN** el usuario ve la lista de artículos en el inbox, archivo o favoritos
- **THEN** el tamaño de fuente de los títulos y subtítulos de esas listas permanece igual al actual

### Requirement: Interlineado coherente con el nuevo tamaño de fuente
El lector SHALL mantener un interlineado (line height) y espaciado entre letras que resulten cómodos de leer para el nuevo tamaño de fuente del cuerpo del artículo.

#### Scenario: Artículo largo con múltiples párrafos
- **WHEN** el usuario lee un artículo con varios párrafos de texto
- **THEN** el espacio vertical entre líneas es suficiente para distinguir claramente cada línea sin sentirse apretado

### Requirement: El contenido raw de email no se ve afectado
El sistema SHALL preservar el renderizado actual de artículos detectados como HTML crudo de email (renderizados en un WebView aislado), sin aplicar el tamaño de fuente del lector a ese contenido.

#### Scenario: Artículo proveniente de un email con marcado VML/Office
- **WHEN** el usuario abre un artículo cuyo contenido fue detectado como HTML crudo de email
- **THEN** el contenido se sigue mostrando dentro de su WebView aislado, sin cambios en su tamaño de fuente

### Requirement: Ancho máximo del cuerpo del artículo
El lector SHALL limitar el ancho del texto del cuerpo del artículo (contenido HTML) a un máximo fijo de aproximadamente 680pt, centrado horizontalmente dentro del espacio disponible, independientemente de si ese espacio es la pantalla completa o el panel derecho de un layout de dos paneles.

#### Scenario: Panel o pantalla más ancha que el máximo
- **WHEN** el ancho disponible para el lector supera los ~680pt
- **THEN** el texto del cuerpo del artículo se muestra con un ancho de ~680pt centrado, dejando márgenes simétricos a los costados

#### Scenario: Panel o pantalla más angosta que el máximo
- **WHEN** el ancho disponible para el lector es menor a ~680pt (por ejemplo, un iPhone en portrait)
- **THEN** el texto del cuerpo del artículo ocupa todo el ancho disponible, igual que el comportamiento actual

#### Scenario: iPhone en landscape
- **WHEN** el usuario abre un artículo en un iPhone en orientación landscape con un ancho disponible mayor a ~680pt
- **THEN** el texto del cuerpo del artículo se limita a ~680pt centrado, en lugar de estirarse al ancho completo de la pantalla
