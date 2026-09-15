## ADDED Requirements

### Requirement: Los links dentro del HTML de un email reenviado se abren en el navegador externo del sistema

El sistema SHALL abrir en el navegador externo del sistema cualquier link que el usuario toque dentro del HTML de un artículo detectado como email crudo, en lugar de navegar el `WebView` embebido a esa URL o ignorar el toque en silencio.

#### Scenario: El usuario toca un link dentro de un email reenviado

- **WHEN** el usuario toca un link dentro del contenido HTML de un artículo detectado como email crudo (ver Requirement "El HTML de un email reenviado se renderiza sin que ninguno de sus scripts se ejecute")
- **THEN** el sistema abre esa URL en el navegador externo del sistema, y el `WebView` embebido permanece mostrando el contenido del email sin navegar a esa URL

#### Scenario: La carga inicial del contenido del email no se ve afectada

- **WHEN** el sistema carga por primera vez el HTML de un artículo detectado como email crudo
- **THEN** esa carga inicial ocurre con normalidad, sin ser interceptada como si fuera un toque en un link
