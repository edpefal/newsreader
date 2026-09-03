## ADDED Requirements

### Requirement: El HTML de un email reenviado se renderiza sin que ninguno de sus scripts se ejecute
El sistema SHALL renderizar el HTML crudo de un email reenviado (ver Requirement "Ausencia de imagen no es una condición de fallo" y detección de email crudo en `feed-polling`/`email-to-rss-feeds`) de forma que ningún script contenido en ese HTML se ejecute, sin importar la forma que tome (etiqueta `<script>`, atributo `on*=`, URI `javascript:`, u otro), dado que ese contenido proviene de un remitente no confiable.

#### Scenario: Email reenviado con un `<script>` embebido
- **WHEN** el contenido de un artículo detectado como email crudo incluye una etiqueta `<script>` o un atributo `onload`/`onclick` con código
- **THEN** el sistema renderiza el resto del HTML normalmente, pero ese código no se ejecuta

#### Scenario: El resto del contenido del email se sigue viendo completo
- **WHEN** el usuario abre un artículo detectado como email crudo, en cualquier orientación del dispositivo
- **THEN** el sistema muestra el contenido completo del email, ajustando su tamaño dinámicamente al contenido real (sin cortarlo a una altura fija) y permitiendo desplazarse por él igual que por el resto de los artículos

#### Scenario: WebView del artículo original no se ve afectado
- **WHEN** el usuario abre la vista de "ver artículo original" (navegación a la URL pública del artículo)
- **THEN** el sistema mantiene JavaScript habilitado en ese WebView, sin cambios respecto del comportamiento existente
