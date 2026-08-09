## MODIFIED Requirements

### Requirement: AddSourceScreen ofrece generar un email cuando falla la detección automática
El sistema SHALL, cuando `AddSource` lanza `FeedDiscoveryException`, ofrecer en `AddSourceScreen` una alternativa para generar una dirección de email además del mensaje de error existente. Este aviso de error SHALL permanecer visible hasta que el usuario lo cierre explícitamente (mediante un ícono de cerrar), reintente agregar una fuente, o abandone la pantalla, sin ocultarse por el paso del tiempo.

#### Scenario: Falla la detección automática de feed
- **WHEN** el usuario ingresa una URL y la detección automática de feed falla (`FeedDiscoveryException`)
- **THEN** además del mensaje de error, se muestra la opción "Generar dirección de email"

#### Scenario: Usuario genera una dirección de email y se agrega como fuente
- **WHEN** el usuario elige "Generar dirección de email", recibe la dirección generada, y confirma
- **THEN** el feed generado se agrega como fuente nueva usando el flujo de `AddSource` existente, sin requerir que el usuario pegue ninguna URL manualmente

#### Scenario: Instrucciones claras tras generar la dirección
- **WHEN** se genera exitosamente una dirección de email
- **THEN** el sistema muestra la dirección junto con instrucciones para suscribir el newsletter usando esa dirección, y una acción para copiarla

#### Scenario: Usuario cierra el aviso de error manualmente
- **WHEN** el aviso de error de detección está visible y el usuario toca el ícono de cerrar
- **THEN** el aviso se oculta inmediatamente

#### Scenario: Usuario reintenta agregar una fuente con el aviso de error visible
- **WHEN** el aviso de error de detección está visible y el usuario vuelve a tocar "Agregar" para intentar con otra URL
- **THEN** el aviso de error previo se oculta antes o al iniciar el nuevo intento

#### Scenario: Usuario abandona AddSourceScreen con el aviso de error visible
- **WHEN** el aviso de error de detección está visible y el usuario sale de `AddSourceScreen` (navegación hacia atrás o a otra pantalla)
- **THEN** el aviso se oculta y no permanece visible en otras pantallas de la app
