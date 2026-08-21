## Purpose

Permite que la app muestre su interfaz (texto de UI y formato de fechas) en el idioma del dispositivo del usuario, entre un conjunto de idiomas soportados, con un idioma por defecto predecible cuando el dispositivo usa uno no soportado.

## ADDED Requirements

### Requirement: Idiomas soportados
La app SHALL soportar inglés, español y francés como idiomas de interfaz.

#### Scenario: Los tres idiomas soportados están disponibles
- **WHEN** el dispositivo del usuario está configurado en inglés, español o francés
- **THEN** la app muestra toda su interfaz en ese idioma

### Requirement: Detección automática del idioma del dispositivo
La app SHALL determinar el idioma de su interfaz a partir del idioma configurado en el dispositivo del usuario, sin requerir selección manual dentro de la app.

#### Scenario: Dispositivo en un idioma soportado
- **WHEN** el usuario abre la app y su dispositivo está configurado en español
- **THEN** la app se muestra en español, sin que el usuario deba elegir un idioma

#### Scenario: Cambio de idioma del dispositivo entre sesiones
- **WHEN** el usuario cambia el idioma de su dispositivo de un idioma soportado a otro y vuelve a abrir la app
- **THEN** la app se muestra en el nuevo idioma configurado en el dispositivo

### Requirement: Inglés como idioma por defecto
Cuando el idioma configurado en el dispositivo del usuario no sea ninguno de los idiomas soportados, la app SHALL mostrar su interfaz en inglés.

#### Scenario: Dispositivo en un idioma no soportado
- **WHEN** el usuario abre la app y su dispositivo está configurado en un idioma que no es inglés, español ni francés (por ejemplo, portugués)
- **THEN** la app se muestra en inglés

### Requirement: Español neutro
Cuando la app se muestre en español, el texto SHALL usar una variante neutra latinoamericana con tuteo, sin modismos ni conjugaciones de voseo regional.

#### Scenario: Texto de interfaz en español no usa voseo
- **WHEN** la app se muestra en español
- **THEN** ningún texto de la interfaz usa conjugaciones de voseo (por ejemplo, "tocá", "agregá") en lugar de tuteo (por ejemplo, "toca", "agrega")

### Requirement: Formato de fechas según el idioma activo
Las fechas mostradas en la interfaz (fechas de publicación de artículos, separadores de fecha, fechas de resúmenes) SHALL presentarse en el formato y con los nombres de mes correspondientes al idioma activo de la app.

#### Scenario: Fecha larga en inglés
- **WHEN** la app está en inglés y muestra la fecha de publicación de un artículo
- **THEN** la fecha se muestra con nombres de mes y orden en inglés (por ejemplo, "March 15, 2024")

#### Scenario: Fecha larga en francés
- **WHEN** la app está en francés y muestra la fecha de publicación de un artículo
- **THEN** la fecha se muestra con nombres de mes y orden en francés (por ejemplo, "15 mars 2024")

#### Scenario: Etiquetas relativas de "hoy" y "ayer" según el idioma
- **WHEN** la app muestra un separador de fecha para un artículo publicado el día actual o el día anterior
- **THEN** la etiqueta relativa ("Today"/"Hoy"/"Aujourd'hui", "Yesterday"/"Ayer"/"Hier") se muestra en el idioma activo de la app
