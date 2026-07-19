## ADDED Requirements

### Requirement: AddSourceScreen ofrece generar un email cuando falla la detección automática
El sistema SHALL, cuando `AddSource` lanza `FeedDiscoveryException`, ofrecer en `AddSourceScreen` una alternativa para generar una dirección de email además del mensaje de error existente.

#### Scenario: Falla la detección automática de feed
- **WHEN** el usuario ingresa una URL y la detección automática de feed falla (`FeedDiscoveryException`)
- **THEN** además del mensaje de error, se muestra la opción "Generar dirección de email"

#### Scenario: Usuario genera una dirección de email y se agrega como fuente
- **WHEN** el usuario elige "Generar dirección de email", recibe la dirección generada, y confirma
- **THEN** el feed generado se agrega como fuente nueva usando el flujo de `AddSource` existente, sin requerir que el usuario pegue ninguna URL manualmente

#### Scenario: Instrucciones claras tras generar la dirección
- **WHEN** se genera exitosamente una dirección de email
- **THEN** el sistema muestra la dirección junto con instrucciones para suscribir el newsletter usando esa dirección, y una acción para copiarla
