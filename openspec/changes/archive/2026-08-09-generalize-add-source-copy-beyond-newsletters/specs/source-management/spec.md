## MODIFIED Requirements

### Requirement: AddSourceScreen acepta URLs de cualquier sitio con feed además de feeds exactos
El sistema SHALL mostrar en `AddSourceScreen` un texto explicativo y un hint de ejemplo que reflejen que el campo acepta tanto el link humano de un sitio (blog, newsletter, medio, podcast) como la URL exacta del feed RSS/Atom, sin limitar el copy a la noción de "newsletter".

#### Scenario: Copy de la pantalla refleja ambas opciones
- **WHEN** el usuario abre la pantalla de agregar fuente
- **THEN** visualiza el texto "Pega el link del sitio (o la URL del feed RSS si la tienes)." y el hint de ejemplo `https://autor.substack.com`
