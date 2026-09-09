## MODIFIED Requirements

### Requirement: Los archivos exportados se comparten mediante el mecanismo nativo del dispositivo
El sistema SHALL, tras generar los archivos de exportación, ofrecer compartirlos usando el mecanismo nativo de compartir del sistema operativo (por ejemplo, para guardarlos, enviarlos por correo, o abrirlos en otra app), sin requerir conexión a internet para completar la exportación. La presentación SHALL funcionar en iPhone con iOS 26 y en iPad.

#### Scenario: Exportación funciona sin conexión
- **WHEN** el usuario solicita exportar sus datos sin conexión a internet
- **THEN** el sistema genera los archivos igual, ya que los datos ya están disponibles localmente, y ofrece compartirlos

#### Scenario: Presentación en dispositivos iOS que requieren un origen
- **WHEN** el usuario exporta sus datos en iPhone con iOS 26 o en iPad
- **THEN** se presenta el menú nativo con los archivos OPML y JSON
