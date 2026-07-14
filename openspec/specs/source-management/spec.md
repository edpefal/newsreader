# Capability: Source Management

## Purpose

Gestión de fuentes RSS/Atom del usuario: agregar fuentes manualmente por URL, importar desde OPML, renombrar y eliminar fuentes existentes.

---

## Requirements

### Requirement: AddSourceScreen ofrece la opción de importar desde OPML
El sistema SHALL mostrar un botón o acción secundaria "Importar desde OPML" en `AddSourceScreen`, como alternativa al ingreso manual de URL.

#### Scenario: Acceso a importación OPML desde AddSourceScreen
- **WHEN** el usuario está en la pantalla de agregar fuente
- **THEN** visualiza una opción secundaria "Importar desde OPML" además del campo de URL manual

#### Scenario: Flujo de navegación desde AddSourceScreen a ImportOpmlScreen
- **WHEN** el usuario selecciona "Importar desde OPML" y elige un archivo
- **THEN** el sistema navega a `/sources/import-opml` con el contenido del archivo como parámetro

---

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

---

### Requirement: AddSourceScreen acepta URLs de newsletter además de feeds exactos
El sistema SHALL mostrar en `AddSourceScreen` un texto explicativo y un hint de ejemplo que reflejen que el campo acepta tanto el link del newsletter como la URL exacta del feed RSS.

#### Scenario: Copy de la pantalla refleja ambas opciones
- **WHEN** el usuario abre la pantalla de agregar fuente
- **THEN** visualiza el texto "Pega el link de tu newsletter (o la URL del feed RSS si la tienes)." y el hint de ejemplo `https://autor.substack.com`

---

### Requirement: Verificación de duplicado sobre la feed URL final resuelta
El sistema SHALL verificar si una fuente ya existe usando la feed URL final que efectivamente resultó válida (tras aplicar, si corresponde, la detección automática), no la URL cruda ingresada por el usuario.

#### Scenario: Usuario reingresa la URL humana de una fuente ya agregada
- **WHEN** el usuario ingresa una URL humana de newsletter cuya feed URL resuelta ya corresponde a una fuente existente
- **THEN** el sistema informa que la fuente ya existe, después de resolver la feed URL correspondiente

#### Scenario: Usuario reingresa la feed URL exacta de una fuente ya agregada
- **WHEN** el usuario ingresa directamente la feed URL exacta de una fuente ya existente
- **THEN** el sistema informa que la fuente ya existe
