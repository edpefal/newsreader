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

### Requirement: Al agregar una fuente exitosamente, navegar a su detalle y sincronizarla
El sistema SHALL, tras agregar una fuente exitosamente, navegar a la pantalla de detalle de esa fuente en vez de permanecer únicamente en la lista de fuentes. Al entrar a esa pantalla como consecuencia directa de haber agregado la fuente, el sistema SHALL disparar automáticamente una sincronización de feeds (ver capability `feed-polling`) antes de mostrar los artículos, mostrando el indicador de carga ya usado para la carga inicial del detalle de una fuente mientras la sincronización está en curso.

Un error durante esa sincronización SHALL manejarse en silencio: el sistema SHALL mostrar los artículos que hayan quedado disponibles localmente (potencialmente ninguno) sin mostrar ningún mensaje de error, ya que la fuente ya fue validada al momento de agregarla.

Esta sincronización automática SHALL dispararse únicamente en este flujo (inmediatamente después de agregar la fuente), no cada vez que el usuario entra al detalle de una fuente ya existente por otros medios (ej. desde la lista de fuentes).

#### Scenario: Fuente agregada exitosamente navega a su detalle
- **WHEN** el usuario agrega una fuente y la validación de feed resulta exitosa
- **THEN** el sistema navega a la pantalla de detalle de esa fuente

#### Scenario: El detalle sincroniza automáticamente tras agregar la fuente
- **WHEN** el usuario llega a la pantalla de detalle de una fuente inmediatamente después de agregarla
- **THEN** el sistema muestra un indicador de carga, dispara la sincronización de feeds, y luego muestra los artículos ya disponibles para esa fuente

#### Scenario: La sincronización automática falla
- **WHEN** la sincronización disparada al entrar al detalle de una fuente recién agregada falla (sin conexión, error de red, o timeout)
- **THEN** el sistema no muestra ningún mensaje de error; muestra los artículos que haya disponibles localmente para esa fuente (potencialmente ninguno)

#### Scenario: Entrar al detalle de una fuente existente no dispara sincronización automática
- **WHEN** el usuario entra al detalle de una fuente ya existente desde la lista de fuentes (no inmediatamente después de agregarla)
- **THEN** el sistema carga los artículos ya disponibles localmente sin disparar una sincronización automática

---

### Requirement: La lista de fuentes se actualiza al navegar al tab de Fuentes
El sistema SHALL recargar la lista de fuentes cada vez que el usuario toca el tab "Fuentes" en la barra de navegación inferior, de forma consistente con el comportamiento de los tabs Favoritos y Leídos. Al volver de agregar una fuente exitosamente, el sistema SHALL recargar la lista de fuentes independientemente de que la navegación continúe hacia el detalle de la fuente recién agregada (ver requirement "Al agregar una fuente exitosamente, navegar a su detalle y sincronizarla").

#### Scenario: Usuario toca el tab Fuentes después de importar OPML
- **WHEN** el usuario importa fuentes vía OPML y luego toca el tab "Fuentes"
- **THEN** la lista muestra las fuentes recién importadas sin necesidad de reiniciar la app ni hacer pull-to-refresh

#### Scenario: Usuario agrega una fuente manualmente
- **WHEN** el usuario agrega una fuente manualmente vía URL exitosamente
- **THEN** la lista de fuentes queda actualizada con la fuente recién agregada, aunque la navegación inmediata sea hacia el detalle de esa fuente y no hacia la lista

#### Scenario: Usuario toca el tab Fuentes ya estando en él
- **WHEN** el usuario toca el tab "Fuentes" mientras ya está visible la pantalla de fuentes
- **THEN** la lista se recarga (scroll al inicio si corresponde, sin efecto visual molesto)

---

### Requirement: AddSourceScreen acepta URLs de cualquier sitio con feed además de feeds exactos
El sistema SHALL mostrar en `AddSourceScreen` un texto explicativo y un hint de ejemplo que reflejen que el campo acepta tanto el link humano de un sitio (blog, newsletter, medio, podcast) como la URL exacta del feed RSS/Atom, sin limitar el copy a la noción de "newsletter".

#### Scenario: Copy de la pantalla refleja ambas opciones
- **WHEN** el usuario abre la pantalla de agregar fuente
- **THEN** visualiza el texto "Pega el link del sitio (o la URL del feed RSS si la tienes)." y el hint de ejemplo `https://autor.substack.com`

---

### Requirement: Verificación de duplicado sobre la feed URL final resuelta
El sistema SHALL verificar si una fuente ya existe usando la feed URL final que efectivamente resultó válida (tras aplicar, si corresponde, la detección automática), no la URL cruda ingresada por el usuario.

#### Scenario: Usuario reingresa la URL humana de una fuente ya agregada
- **WHEN** el usuario ingresa una URL humana de newsletter cuya feed URL resuelta ya corresponde a una fuente existente
- **THEN** el sistema informa que la fuente ya existe, después de resolver la feed URL correspondiente

#### Scenario: Usuario reingresa la feed URL exacta de una fuente ya agregada
- **WHEN** el usuario ingresa directamente la feed URL exacta de una fuente ya existente
- **THEN** el sistema informa que la fuente ya existe

---

### Requirement: AddSourceScreen informa cuando falla la detección automática de feed
El sistema SHALL, cuando `AddSource` lanza `FeedDiscoveryException`, mostrar un aviso de error en `AddSourceScreen` con el mensaje correspondiente, sin ninguna acción asociada. Este aviso SHALL permanecer visible hasta que el usuario lo cierre explícitamente (mediante un ícono de cerrar), reintente agregar una fuente, o abandone la pantalla, sin ocultarse por el paso del tiempo.

#### Scenario: Falla la detección automática de feed
- **WHEN** el usuario ingresa una URL y la detección automática de feed falla (`FeedDiscoveryException`)
- **THEN** el sistema muestra el mensaje de error correspondiente, sin ninguna acción asociada al aviso

#### Scenario: Usuario cierra el aviso de error manualmente
- **WHEN** el aviso de error de detección está visible y el usuario toca el ícono de cerrar
- **THEN** el aviso se oculta inmediatamente

#### Scenario: Usuario reintenta agregar una fuente con el aviso de error visible
- **WHEN** el aviso de error de detección está visible y el usuario vuelve a tocar "Agregar" para intentar con otra URL
- **THEN** el aviso de error previo se oculta antes o al iniciar el nuevo intento

#### Scenario: Usuario abandona AddSourceScreen con el aviso de error visible
- **WHEN** el aviso de error de detección está visible y el usuario sale de `AddSourceScreen` (navegación hacia atrás o a otra pantalla)
- **THEN** el aviso se oculta y no permanece visible en otras pantallas de la app

---

### Requirement: AddSourceScreen ofrece una card siempre visible para generar una dirección de email
El sistema SHALL mostrar en `AddSourceScreen`, en una sección "Otras formas de agregar" junto a la opción de importar OPML, una card siempre visible para generar una dirección de email, independientemente de si el usuario intentó o no agregar una fuente por URL. La card SHALL iniciar colapsada mostrando un título y una descripción breve del propósito de la funcionalidad (destinado a newsletters sin feed RSS/Atom descubrible).

Al tocar la card, esta SHALL expandirse (con una transición animada de tamaño) mostrando una explicación más detallada y un botón para disparar la generación de la dirección de email. La generación en sí SHALL reutilizar el flujo existente: al tocar ese botón interno, el sistema dispara `GenerateEmailFeed`, muestra un estado de carga, y luego un diálogo con la dirección generada, instrucciones para suscribir el newsletter, y una acción para agregar el feed generado como fuente.

La card SHALL volver a su estado colapsado automáticamente cuando el usuario genera una dirección de email exitosamente, o cuando agrega una fuente exitosamente por cualquier otra vía (URL u OPML) mientras la card está expandida.

#### Scenario: Card visible sin haber intentado agregar una fuente
- **WHEN** el usuario abre `AddSourceScreen` por primera vez, sin haber ingresado ninguna URL todavía
- **THEN** la card "Generar dirección de email" ya está visible y colapsada, junto a "Importar desde OPML"

#### Scenario: Usuario expande la card
- **WHEN** el usuario toca la card "Generar dirección de email" estando colapsada
- **THEN** la card se expande mostrando una explicación más detallada y un botón para generar la dirección

#### Scenario: Usuario genera una dirección de email desde la card expandida
- **WHEN** el usuario, con la card expandida, toca el botón de generar y confirma la dirección generada
- **THEN** el feed generado se agrega como fuente nueva usando el flujo de `AddSource` existente, sin requerir que el usuario pegue ninguna URL manualmente

#### Scenario: Instrucciones claras tras generar la dirección
- **WHEN** se genera exitosamente una dirección de email
- **THEN** el sistema muestra la dirección junto con instrucciones para suscribir el newsletter usando esa dirección, y una acción para copiarla

#### Scenario: La card se colapsa tras generar exitosamente
- **WHEN** el usuario genera una dirección de email exitosamente desde la card expandida
- **THEN** la card vuelve a su estado colapsado

#### Scenario: La card se colapsa al agregar una fuente por otra vía
- **WHEN** la card está expandida y el usuario agrega una fuente exitosamente por URL o por OPML
- **THEN** la card vuelve a su estado colapsado
