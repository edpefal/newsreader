# Capability: Data Export

## Purpose

Permite al usuario obtener una copia local de sus fuentes suscritas y de sus artículos favoritos en formatos portables, para que pueda conservarlos o migrarlos independientemente de la app.

## Requirements

### Requirement: Punto de entrada para exportar datos
El sistema SHALL mostrar, en el `NavigationDrawer`, una opción "Exportar mis datos" accesible con sesión activa.

#### Scenario: Acceso a la opción desde el drawer
- **WHEN** el usuario abre el `NavigationDrawer` con sesión activa
- **THEN** visualiza una opción "Exportar mis datos"

---

### Requirement: Exportación de fuentes en formato OPML
El sistema SHALL generar, a partir de las fuentes suscritas del usuario ya disponibles localmente, un archivo OPML válido que liste cada fuente con su nombre y su feed URL.

#### Scenario: Exportar con fuentes suscritas
- **WHEN** el usuario solicita la exportación y tiene al menos una fuente suscrita
- **THEN** el sistema genera un archivo `.opml` válido con un `<outline>` por cada fuente, incluyendo su `xmlUrl`

#### Scenario: Exportar sin fuentes suscritas
- **WHEN** el usuario solicita la exportación sin tener ninguna fuente suscrita
- **THEN** el sistema genera igualmente un OPML válido con cero `<outline>`, sin mostrar un error

---

### Requirement: Exportación de favoritos en formato JSON
El sistema SHALL generar, a partir de los artículos marcados como favoritos ya disponibles localmente, un archivo JSON con al menos título, `articleUrl`, `sourceName` y fecha en que se marcó como favorito de cada artículo.

#### Scenario: Exportar con favoritos existentes
- **WHEN** el usuario solicita la exportación y tiene al menos un artículo favorito
- **THEN** el sistema genera un archivo `.json` válido con un objeto por cada artículo favorito, incluyendo título, `articleUrl`, `sourceName` y `savedAsFavoriteAt`

#### Scenario: Exportar sin favoritos
- **WHEN** el usuario solicita la exportación sin tener ningún artículo favorito
- **THEN** el sistema genera igualmente un JSON válido con una lista vacía, sin mostrar un error

---

### Requirement: Los archivos exportados se comparten mediante el mecanismo nativo del dispositivo
El sistema SHALL, tras generar los archivos de exportación, ofrecer compartirlos usando el mecanismo nativo de compartir del sistema operativo (por ejemplo, para guardarlos, enviarlos por correo, o abrirlos en otra app), sin requerir conexión a internet para completar la exportación.

#### Scenario: Exportación funciona sin conexión
- **WHEN** el usuario solicita exportar sus datos sin conexión a internet
- **THEN** el sistema genera los archivos igual, ya que los datos ya están disponibles localmente, y ofrece compartirlos
