## MODIFIED Requirements

### Requirement: Contador de no leídos legible con números grandes
El sistema SHALL mostrar el contador de artículos no leídos del Inbox en el `NavigationDrawer` de forma que el texto nunca se desborde de su contenedor visual, incluso cuando el conteo es un número de varios dígitos, y sin que el badge se superponga visualmente sobre el ícono ni sobre el texto de la etiqueta del destino Inbox.

#### Scenario: Conteo de no leídos supera las tres cifras
- **WHEN** el conteo de artículos no leídos del Inbox es mayor a 999
- **THEN** el sistema muestra el contador con un formato abreviado (ej. "999+") en vez del número exacto, sin que el texto se desborde del indicador

#### Scenario: Conteo de no leídos de una o dos cifras
- **WHEN** el conteo de artículos no leídos del Inbox es 999 o menos
- **THEN** el sistema muestra el número exacto dentro del indicador, sin desbordarlo

#### Scenario: Badge no se superpone al ícono ni al texto del destino Inbox
- **WHEN** el conteo de artículos no leídos del Inbox es mayor a 0, en cualquier estado de selección del destino (seleccionado o no seleccionado)
- **THEN** el badge se muestra a la derecha del texto de la etiqueta "Inbox", separado tanto del ícono como del texto, sin cubrir ni superponerse visualmente a ninguno de los dos
