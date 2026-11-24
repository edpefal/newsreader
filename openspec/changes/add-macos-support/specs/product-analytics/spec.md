## ADDED Requirements

### Requirement: Plataforma en los eventos
El sistema SHALL incluir en todos los eventos de producto y de pantalla la plataforma en la que ocurren (`ios`, `macos` o `android`), sin incluir información de identificación personal, de modo que el uso se pueda segmentar por plataforma.

#### Scenario: Evento desde macOS
- **WHEN** se registra un evento de producto o un `screen_view` en la app de Mac
- **THEN** el evento lleva la plataforma `macos`

#### Scenario: Evento desde iOS
- **WHEN** se registra un evento de producto o un `screen_view` en la app de iPhone o iPad
- **THEN** el evento lleva la plataforma `ios`

#### Scenario: La plataforma no identifica al usuario
- **WHEN** se registra cualquier evento con la plataforma incluida
- **THEN** el evento no contiene el correo ni ningún otro dato de identificación personal añadido por esta propiedad
