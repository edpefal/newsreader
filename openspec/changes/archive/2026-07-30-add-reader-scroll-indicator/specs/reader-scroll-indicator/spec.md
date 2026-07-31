## ADDED Requirements

### Requirement: Indicador visual de progreso de scroll en el lector
La pantalla de lectura de un artículo (`ReaderScreen`) SHALL mostrar una barra de progreso vertical que refleja la posición relativa del usuario dentro del contenido del artículo, cuando el contenido excede el alto del viewport visible.

#### Scenario: Contenido más largo que el viewport
- **WHEN** el usuario abre un artículo cuyo contenido renderizado excede el alto de la pantalla
- **THEN** se muestra una barra de progreso vertical en la pantalla de lectura

#### Scenario: Contenido que cabe completamente en el viewport
- **WHEN** el usuario abre un artículo cuyo contenido renderizado no excede el alto de la pantalla (no hay scroll posible)
- **THEN** la barra de progreso no se muestra

### Requirement: Actualización en tiempo real del progreso de scroll
La barra de progreso SHALL reflejar, en todo momento, la posición actual de scroll como una proporción entre el inicio (0%) y el final (100%) del contenido.

#### Scenario: Usuario en el inicio del artículo
- **WHEN** el usuario abre el artículo y no ha hecho scroll
- **THEN** la barra de progreso se muestra en su posición inicial (0%)

#### Scenario: Usuario hace scroll manual
- **WHEN** el usuario desplaza el contenido hacia abajo
- **THEN** la barra de progreso avanza proporcionalmente a la posición actual de scroll respecto al contenido total

#### Scenario: Usuario llega al final del artículo
- **WHEN** el usuario hace scroll hasta el final del contenido
- **THEN** la barra de progreso se muestra en su posición final (100%)

### Requirement: El indicador no interfiere con la funcionalidad existente del lector
La adición del indicador de progreso SHALL preservar el comportamiento existente de la pantalla de lectura: marcar el artículo como leído al abrirlo, alternar favorito, y navegar a la vista web del artículo.

#### Scenario: Artículo se marca como leído normalmente
- **WHEN** el usuario abre un artículo desde el inbox, archivo o favoritos
- **THEN** el artículo se marca como leído igual que antes de agregar el indicador de progreso

#### Scenario: Alternar favorito sigue funcionando
- **WHEN** el usuario presiona el botón de favorito en la pantalla de lectura
- **THEN** el estado de favorito del artículo cambia igual que antes de agregar el indicador de progreso
