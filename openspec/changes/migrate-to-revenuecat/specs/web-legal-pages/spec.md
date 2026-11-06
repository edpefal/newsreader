## MODIFIED Requirements

### Requirement: URLs estables aptas para revisión de Apple
Las URLs de `/terms` y `/privacy` SHALL permanecer estables una vez publicadas, de forma que enlaces mostrados en el paywall de la app y en la ficha de la app en App Store Connect sigan resolviendo al contenido correcto.

#### Scenario: Link mostrado en el paywall sigue funcionando
- **WHEN** un revisor de Apple o un usuario final abre el link de Términos/Privacidad mostrado en el paywall
- **THEN** la URL resuelve sin error 404 y muestra el contenido legal vigente
