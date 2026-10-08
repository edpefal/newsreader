## MODIFIED Requirements

### Requirement: Captura de acciones clave de producto

El sistema SHALL registrar un evento de producto cuando el usuario completa cada una de las siguientes acciones: iniciar sesión, agregar una fuente, importar un OPML, eliminar una fuente, disparar una sincronización, solicitar el resumen de un artículo, marcar/desmarcar un artículo como favorito, abrir la tarjeta del resumen diario en el Inbox (`inbox_summary_card_opened`) y descartar esa tarjeta con swipe (`inbox_summary_card_dismissed`). Los dos eventos de la tarjeta SHALL incluir únicamente la cantidad de artículos del resumen (`article_count`), sin ningún contenido del resumen, y SHALL emitirse solo por una acción del usuario sobre la tarjeta en el dispositivo local: NO SHALL emitirse cuando el resumen se abre desde la tab Resúmenes, ni cuando un descarte llega desde otro dispositivo por sincronización. El sistema SHALL registrar únicamente estas acciones explícitamente instrumentadas -- SHALL NOT capturar automáticamente cualquier interacción de UI no listada aquí (sin autocapture genérico).

#### Scenario: Completar una acción instrumentada

- **WHEN** el usuario completa alguna de las acciones instrumentadas (por ejemplo, agrega una fuente exitosamente)
- **THEN** el sistema registra un evento identificando esa acción

#### Scenario: Interacción no instrumentada no genera evento

- **WHEN** el usuario interactúa con un elemento de la UI que no corresponde a ninguna de las acciones instrumentadas
- **THEN** el sistema no registra ningún evento de producto para esa interacción

#### Scenario: Abrir la tarjeta del resumen registra un evento

- **WHEN** el usuario toca la tarjeta del resumen diario en el Inbox
- **THEN** el sistema registra `inbox_summary_card_opened` con `article_count`

#### Scenario: Descartar la tarjeta del resumen registra un evento

- **WHEN** el usuario descarta la tarjeta del resumen diario con swipe
- **THEN** el sistema registra `inbox_summary_card_dismissed` con `article_count`

#### Scenario: Abrir el resumen desde la tab Resúmenes no registra evento de la tarjeta

- **WHEN** el usuario abre el resumen de hoy desde la tab Resúmenes
- **THEN** el sistema no registra ningún evento de la tarjeta, aunque el resumen quede con `dismissed_at`

#### Scenario: Un descarte recibido por sincronización no registra un evento

- **WHEN** una sincronización trae un `dismissed_at` de un resumen descartado en otro dispositivo
- **THEN** el sistema no registra ningún evento de la tarjeta

### Requirement: Alcance explícito del tracking de producto

El sistema SHALL limitar el tracking de producto a los eventos definidos en este spec. El registro de cada lectura individual de artículo (`article_marked_read`), un evento específico de "ver un resumen diario" (ya cubierto por el `screen_view` de esa pantalla; los eventos de la tarjeta del Inbox miden la interacción con esa tarjeta, no la visualización del detalle), funnels, session replay, y experimentos A/B quedan fuera de alcance y SHALL NOT implementarse como parte de esta capability.

#### Scenario: Lectura de un artículo no genera un evento de producto

- **WHEN** el usuario abre y marca como leído un artículo
- **THEN** el sistema no registra un evento de producto específico para esa lectura

#### Scenario: Ver un resumen diario no genera un evento de producto aparte del screen_view

- **WHEN** el usuario navega al detalle de un resumen diario
- **THEN** el sistema registra el `screen_view` de esa pantalla, y no un evento de producto adicional específico para esa vista, más allá del evento de la tarjeta si la navegación partió de ella
