## MODIFIED Requirements

### Requirement: "Leídos" muestra los artículos que el usuario ha abierto
El sistema SHALL mostrar en "Leídos" todos los artículos con `isRead=true`, ordenados por `publishedAt` descendente (más reciente primero), igual que el Inbox. Los artículos leídos SHALL permanecer en "Leídos" indefinidamente.

#### Scenario: Artículo leído aparece en "Leídos"
- **WHEN** el usuario abre un artículo
- **THEN** ese artículo aparece en "Leídos" al navegar a esa pantalla

#### Scenario: Orden por fecha de publicación
- **WHEN** el usuario navega a "Leídos"
- **THEN** los artículos aparecen ordenados por fecha de publicación, el más reciente primero, igual que en el Inbox

#### Scenario: Separadores de fecha coherentes con el orden
- **WHEN** el usuario navega a "Leídos" y hay artículos de distintos días
- **THEN** los separadores de fecha aparecen en orden descendente (hoy primero, ayer después)

#### Scenario: Artículos leídos no expiran
- **WHEN** un artículo lleva más de 30 días en "Leídos"
- **THEN** el artículo permanece en "Leídos" sin cambios
