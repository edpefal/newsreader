## Purpose

Define qué se le muestra al usuario en el lector cuando el contenido de un artículo está truncado o ausente en el feed de origen, y cómo accede desde ahí a la alternativa de leerlo completo en el sitio original.

## ADDED Requirements

### Requirement: Aviso tocable cuando el contenido está truncado o ausente
El sistema SHALL, cuando `article.contentHtml` sea considerado truncado según el criterio ya existente (nulo, vacío, o menor a 500 caracteres), mostrar en el lector un aviso indicando que el feed no incluye el artículo completo, además de cualquier contenido parcial disponible (excerpt o HTML corto). Ese aviso SHALL ser tocable: al tocarlo, el sistema SHALL navegar a la misma pantalla de WebView que abre el ícono "Ver en navegador" del AppBar.

#### Scenario: Feed sin ningún contenido (ej. tldr.tech)
- **WHEN** el artículo tiene `contentHtml` nulo y `excerpt` nulo
- **THEN** el lector muestra el aviso de contenido truncado, tocable, sin ningún otro texto de contenido

#### Scenario: Feed con excerpt pero sin contentHtml
- **WHEN** el artículo tiene `contentHtml` nulo pero `excerpt` no nulo
- **THEN** el lector muestra el excerpt, y debajo el aviso de contenido truncado, tocable

#### Scenario: Feed con contentHtml presente pero por debajo del umbral de truncamiento
- **WHEN** el artículo tiene `contentHtml` no nulo pero de menos de 500 caracteres
- **THEN** el lector muestra ese HTML, y debajo el aviso de contenido truncado, tocable

#### Scenario: Tocar el aviso abre el artículo en el WebView
- **WHEN** el usuario toca el aviso de contenido truncado
- **THEN** el sistema navega a la pantalla de WebView del artículo, la misma a la que navega el ícono "Ver en navegador" del AppBar

#### Scenario: Contenido suficiente no muestra ningún aviso
- **WHEN** el artículo tiene `contentHtml` no nulo y de 500 caracteres o más
- **THEN** el lector muestra ese contenido sin ningún aviso adicional
