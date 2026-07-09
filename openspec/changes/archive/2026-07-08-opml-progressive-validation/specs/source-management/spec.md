## ADDED Requirements

### Requirement: La lista de fuentes se actualiza al navegar al tab de Fuentes
El sistema SHALL recargar la lista de fuentes cada vez que el usuario toca el tab "Fuentes" en la barra de navegación inferior, de forma consistente con el comportamiento de los tabs Favoritos y Leídos.

#### Scenario: Usuario toca el tab Fuentes después de importar OPML
- **WHEN** el usuario importa fuentes vía OPML y luego toca el tab "Fuentes"
- **THEN** la lista muestra las fuentes recién importadas sin necesidad de reiniciar la app ni hacer pull-to-refresh

#### Scenario: Usuario toca el tab Fuentes después de agregar una fuente manualmente
- **WHEN** el usuario agrega una fuente manualmente vía URL y luego toca el tab "Fuentes"
- **THEN** la lista muestra la fuente recién agregada

#### Scenario: Usuario toca el tab Fuentes ya estando en él
- **WHEN** el usuario toca el tab "Fuentes" mientras ya está visible la pantalla de fuentes
- **THEN** la lista se recarga (scroll al inicio si corresponde, sin efecto visual molesto)
