## ADDED Requirements

### Requirement: AddSourceScreen acepta URLs de newsletter además de feeds exactos
El sistema SHALL mostrar en `AddSourceScreen` un texto explicativo y un hint de ejemplo que reflejen que el campo acepta tanto el link del newsletter como la URL exacta del feed RSS.

#### Scenario: Copy de la pantalla refleja ambas opciones
- **WHEN** el usuario abre la pantalla de agregar fuente
- **THEN** visualiza el texto "Pega el link de tu newsletter (o la URL del feed RSS si la tienes)." y el hint de ejemplo `https://autor.substack.com`

### Requirement: Verificación de duplicado sobre la feed URL final resuelta
El sistema SHALL verificar si una fuente ya existe usando la feed URL final que efectivamente resultó válida (tras aplicar, si corresponde, la detección automática), no la URL cruda ingresada por el usuario.

#### Scenario: Usuario reingresa la URL humana de una fuente ya agregada
- **WHEN** el usuario ingresa una URL humana de newsletter cuya feed URL resuelta ya corresponde a una fuente existente
- **THEN** el sistema informa que la fuente ya existe, después de resolver la feed URL correspondiente

#### Scenario: Usuario reingresa la feed URL exacta de una fuente ya agregada
- **WHEN** el usuario ingresa directamente la feed URL exacta de una fuente ya existente
- **THEN** el sistema informa que la fuente ya existe
