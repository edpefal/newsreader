## ADDED Requirements

### Requirement: Workflow de Codemagic configurable con default a iOS
El disparo manual SHALL aceptar como input el workflow de Codemagic a lanzar, con `ios-testflight` como valor por defecto, y SHALL aceptar `macos-testflight` para lanzar el build de macOS. El sistema SHALL rechazar cualquier otro valor antes de llamar a la API de Codemagic.

#### Scenario: Disparo sin especificar workflow
- **WHEN** un colaborador dispara el workflow sin indicar cuál lanzar
- **THEN** Codemagic recibe la solicitud de build del workflow `ios-testflight`

#### Scenario: Disparo del build de macOS
- **WHEN** un colaborador dispara el workflow indicando `macos-testflight`
- **THEN** Codemagic recibe la solicitud de build del workflow `macos-testflight`

#### Scenario: Workflow inválido
- **WHEN** un colaborador indica un workflow que no es `ios-testflight` ni `macos-testflight`
- **THEN** el job termina en fallo con un mensaje que lo indica, sin llamar a la API de Codemagic
