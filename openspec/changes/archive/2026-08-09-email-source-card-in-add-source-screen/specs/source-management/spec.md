## REMOVED Requirements

### Requirement: AddSourceScreen ofrece generar un email cuando falla la detección automática
**Reason**: La generación de dirección de email deja de depender de que falle la detección automática de feed. Pasa a ser una alternativa siempre visible en `AddSourceScreen`, independiente del resultado de la detección (ver requirements "AddSourceScreen informa cuando falla la detección automática de feed" y "AddSourceScreen ofrece una card siempre visible para generar una dirección de email").
**Migration**: N/A — cambio de UX interno, sin impacto en datos, contratos de API, ni comportamiento del backend de `email-to-rss-feeds`.

## ADDED Requirements

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
