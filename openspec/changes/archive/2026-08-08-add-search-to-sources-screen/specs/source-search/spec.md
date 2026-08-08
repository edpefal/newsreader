## Purpose

Permite al usuario encontrar rápidamente una fuente dentro de la lista ya cargada en la pantalla de Fuentes, filtrando por nombre o autor, sin depender de scroll manual ni de una consulta nueva al repositorio local.

## ADDED Requirements

### Requirement: Búsqueda local disponible en la pantalla de Fuentes
El sistema SHALL mostrar un ícono de búsqueda en el `AppBar` cuando el tab activo es "Fuentes", igual mecanismo que ya usan Inbox, Favoritos y Leídos. Al activarlo, SHALL mostrar un campo de texto que filtra, en memoria, la lista de fuentes ya cargada en esa pantalla, sin consultar el repositorio local.

#### Scenario: Activar la búsqueda en Fuentes
- **WHEN** el usuario toca el ícono de búsqueda estando en el tab "Fuentes"
- **THEN** aparece un campo de texto en el `AppBar`, y la lista de fuentes visible es la misma ya cargada, sin disparar ninguna carga adicional

#### Scenario: La búsqueda de Fuentes es independiente de la de artículos
- **WHEN** el usuario escribe una búsqueda en Inbox (o Favoritos, o Leídos) y luego navega al tab "Fuentes"
- **THEN** el tab "Fuentes" no conserva ni aplica el texto de búsqueda que se había escrito en el otro tab

---

### Requirement: Coincidencia por nombre o autor de la fuente
El sistema SHALL filtrar la lista mostrada incluyendo únicamente las fuentes cuyo `name` o `author` contenga el texto ingresado, de forma insensible a mayúsculas/minúsculas y por coincidencia parcial (substring).

#### Scenario: Coincidencia por nombre
- **WHEN** el usuario escribe un texto que es substring del `name` de una fuente, sin importar mayúsculas o minúsculas
- **THEN** esa fuente aparece en los resultados

#### Scenario: Coincidencia por autor
- **WHEN** el usuario escribe un texto que es substring del `author` de una fuente, aunque no coincida con su nombre
- **THEN** esa fuente aparece en los resultados

#### Scenario: Sin coincidencias
- **WHEN** el texto ingresado no es substring del `name` ni del `author` de ninguna fuente de la lista
- **THEN** la lista se muestra vacía con un mensaje distinguible del estado vacío por "sin fuentes agregadas"

---

### Requirement: Limpiar la búsqueda restaura la lista completa
El sistema SHALL, al limpiar o cerrar el campo de búsqueda, volver a mostrar la lista completa de fuentes ya cargada, sin necesidad de recargarla desde el repositorio.

#### Scenario: Cerrar la búsqueda
- **WHEN** el usuario cierra o borra completamente el campo de búsqueda estando en el tab "Fuentes"
- **THEN** la lista vuelve a mostrar todas las fuentes que ya estaban cargadas antes de buscar, sin mostrar un estado de carga
