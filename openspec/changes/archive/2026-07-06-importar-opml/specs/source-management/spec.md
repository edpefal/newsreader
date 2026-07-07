## ADDED Requirements

### Requirement: AddSourceScreen ofrece la opción de importar desde OPML
El sistema SHALL mostrar un botón o acción secundaria "Importar desde OPML" en `AddSourceScreen`, como alternativa al ingreso manual de URL.

#### Scenario: Acceso a importación OPML desde AddSourceScreen
- **WHEN** el usuario está en la pantalla de agregar fuente
- **THEN** visualiza una opción secundaria "Importar desde OPML" además del campo de URL manual

#### Scenario: Flujo de navegación desde AddSourceScreen a ImportOpmlScreen
- **WHEN** el usuario selecciona "Importar desde OPML" y elige un archivo
- **THEN** el sistema navega a `/sources/import-opml` con el contenido del archivo como parámetro
