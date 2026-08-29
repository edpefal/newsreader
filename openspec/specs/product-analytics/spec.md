## Purpose

Define qué eventos de uso de producto captura el sistema (pantallas visitadas y acciones clave del usuario), cómo se asocian a un usuario sin exponer información personal, y qué queda explícitamente fuera de este tracking.

## Requirements

### Requirement: Captura de vistas de pantalla

El sistema SHALL registrar un evento cuando el usuario navega a cualquiera de las rutas principales de la app (Inbox, Lector, Archivo, Favoritos, Fuentes, Agregar fuente), identificando qué pantalla fue visitada, sin requerir instrumentación manual en cada pantalla individual.

#### Scenario: Usuario navega entre pantallas

- **WHEN** el usuario navega de una ruta principal a otra (por ejemplo, de Inbox al Lector)
- **THEN** el sistema registra un evento identificando la pantalla de destino

### Requirement: Captura de acciones clave de producto

El sistema SHALL registrar un evento de producto cuando el usuario completa cada una de las siguientes acciones: iniciar sesión, agregar una fuente, importar un OPML, eliminar una fuente, disparar una sincronización, solicitar el resumen de un artículo, y marcar/desmarcar un artículo como favorito. El sistema SHALL registrar únicamente estas acciones explícitamente instrumentadas -- SHALL NOT capturar automáticamente cualquier interacción de UI no listada aquí (sin autocapture genérico).

#### Scenario: Completar una acción instrumentada

- **WHEN** el usuario completa alguna de las acciones instrumentadas (por ejemplo, agrega una fuente exitosamente)
- **THEN** el sistema registra un evento identificando esa acción

#### Scenario: Interacción no instrumentada no genera evento

- **WHEN** el usuario interactúa con un elemento de la UI que no corresponde a ninguna de las acciones instrumentadas
- **THEN** el sistema no registra ningún evento de producto para esa interacción

### Requirement: Asociación de eventos con el usuario activo, sin PII

El sistema SHALL asociar los eventos de producto con el identificador del usuario con sesión activa cuando exista una, y SHALL dejar de asociarlos a ese usuario cuando la sesión termine, sin incluir información de identificación personal (como el email) en ningún evento ni en la identidad asociada.

#### Scenario: Evento mientras hay una sesión activa

- **WHEN** se registra un evento de producto mientras el usuario tiene una sesión iniciada
- **THEN** el evento queda asociado al identificador de ese usuario, sin incluir su email

#### Scenario: Evento tras cerrar sesión

- **WHEN** el usuario cierra sesión o elimina su cuenta y luego se registra un evento de producto
- **THEN** el evento ya no se asocia al usuario anterior

### Requirement: Alcance explícito del tracking de producto

El sistema SHALL limitar el tracking de producto a los eventos definidos en este spec. El registro de cada lectura individual de artículo (`article_marked_read`), un evento específico de "ver un resumen diario" (ya cubierto por el `screen_view` de esa pantalla), funnels, session replay, y experimentos A/B quedan fuera de alcance y SHALL NOT implementarse como parte de esta capability.

#### Scenario: Lectura de un artículo no genera un evento de producto

- **WHEN** el usuario abre y marca como leído un artículo
- **THEN** el sistema no registra un evento de producto específico para esa lectura

#### Scenario: Ver un resumen diario no genera un evento de producto aparte del screen_view

- **WHEN** el usuario navega al detalle de un resumen diario
- **THEN** el sistema registra el `screen_view` de esa pantalla, y no un evento de producto adicional específico para esa vista
