## Purpose

Permite al usuario encontrar rápidamente un artículo dentro de una lista ya cargada (Inbox, Leídos o Favoritos) filtrando por título, fuente o autor, sin depender de scroll manual ni de una consulta nueva a la base de datos local o remota.

## ADDED Requirements

### Requirement: Búsqueda local disponible en Inbox, Leídos y Favoritos
El sistema SHALL mostrar un ícono de búsqueda en el `AppBar` de las pantallas Inbox, Leídos y Favoritos. Al activarlo, SHALL mostrar un campo de texto que filtra, en memoria, la lista de artículos ya cargada en esa pantalla, sin consultar el repositorio local ni remoto.

#### Scenario: Activar la búsqueda en el Inbox
- **WHEN** el usuario toca el ícono de búsqueda en el Inbox
- **THEN** aparece un campo de texto en el `AppBar`, y la lista de artículos visible es la misma ya cargada, sin disparar ninguna carga adicional

#### Scenario: La búsqueda es independiente por pantalla
- **WHEN** el usuario escribe una búsqueda en Inbox y luego navega a Favoritos
- **THEN** la pantalla de Favoritos no conserva ni aplica el texto de búsqueda que se había escrito en Inbox

---

### Requirement: Coincidencia por título, fuente o autor
El sistema SHALL filtrar la lista mostrada incluyendo únicamente los artículos cuyo título, `sourceName` o `author` contenga el texto ingresado, de forma insensible a mayúsculas/minúsculas y por coincidencia parcial (substring). El sistema NO SHALL considerar `contentHtml` ni `excerpt` para el filtrado.

#### Scenario: Coincidencia por título
- **WHEN** el usuario escribe un texto que es substring del título de un artículo, sin importar mayúsculas o minúsculas
- **THEN** ese artículo aparece en los resultados

#### Scenario: Coincidencia por nombre de fuente
- **WHEN** el usuario escribe un texto que es substring del `sourceName` de un artículo, aunque no coincida con su título
- **THEN** ese artículo aparece en los resultados

#### Scenario: Coincidencia por autor
- **WHEN** el usuario escribe un texto que es substring del `author` de un artículo, aunque no coincida con su título ni su fuente
- **THEN** ese artículo aparece en los resultados

#### Scenario: Sin coincidencias
- **WHEN** el texto ingresado no es substring del título, `sourceName` ni `author` de ningún artículo de la lista
- **THEN** la lista se muestra vacía con un mensaje distinguible del estado vacío por "sin artículos"

#### Scenario: El contenido del artículo no participa del filtrado
- **WHEN** el texto ingresado coincide con una palabra presente en `contentHtml` o `excerpt` de un artículo, pero no en su título, `sourceName` ni `author`
- **THEN** ese artículo NO aparece en los resultados

---

### Requirement: Limpiar la búsqueda restaura la lista completa
El sistema SHALL, al limpiar o cerrar el campo de búsqueda, volver a mostrar la lista completa ya cargada en la pantalla, sin necesidad de recargarla desde el repositorio.

#### Scenario: Cerrar la búsqueda
- **WHEN** el usuario cierra o borra completamente el campo de búsqueda
- **THEN** la lista vuelve a mostrar todos los artículos que ya estaban cargados antes de buscar, sin mostrar un estado de carga
