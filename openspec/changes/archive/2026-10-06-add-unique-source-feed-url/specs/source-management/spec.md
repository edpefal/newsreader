## MODIFIED Requirements

### Requirement: Verificación de duplicado sobre la feed URL final resuelta
El sistema SHALL verificar si una fuente ya existe usando la feed URL final que efectivamente resultó válida (tras aplicar, si corresponde, la detección automática), no la URL cruda ingresada por el usuario. La verificación SHALL considerar tanto las fuentes activas del dispositivo como, cuando hay sesión iniciada y conexión, las fuentes activas del mismo usuario que existen en la nube aunque todavía no se hayan sincronizado al dispositivo. Si la consulta a la nube falla por cualquier motivo (sin red, timeout, error del servidor), el sistema SHALL continuar solo con la verificación local, sin impedir agregar la fuente ni mostrar un error por ese motivo.

#### Scenario: Usuario reingresa la URL humana de una fuente ya agregada
- **WHEN** el usuario ingresa una URL humana de newsletter cuya feed URL resuelta ya corresponde a una fuente existente
- **THEN** el sistema informa que la fuente ya existe, después de resolver la feed URL correspondiente

#### Scenario: Usuario reingresa la feed URL exacta de una fuente ya agregada
- **WHEN** el usuario ingresa directamente la feed URL exacta de una fuente ya existente
- **THEN** el sistema informa que la fuente ya existe

#### Scenario: La fuente existe en la nube pero todavía no en este dispositivo
- **WHEN** el usuario agrega una feed URL que ya tiene como fuente activa en su cuenta (agregada desde otro dispositivo) y que este dispositivo aún no sincronizó, con sesión iniciada y conexión disponible
- **THEN** el sistema informa que la fuente ya existe y no crea una fuente nueva

#### Scenario: No se puede consultar la nube al agregar
- **WHEN** el usuario agrega una feed URL que no existe en el dispositivo y la consulta a la nube falla o no hay sesión iniciada
- **THEN** el sistema agrega la fuente normalmente usando solo la verificación local, sin mostrar ningún error de red

#### Scenario: La fuente duplicada solo existe borrada en la nube
- **WHEN** el usuario agrega una feed URL cuya única fuente en la nube está marcada como borrada
- **THEN** el sistema no la considera duplicada y agrega la fuente normalmente
