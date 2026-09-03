## Purpose

Define cómo se renderiza el HTML del contenido de un artículo dentro del lector, incluyendo el manejo de elementos embebidos (como iframes de video) que requieren tratamiento especial para funcionar correctamente dentro de un WebView aislado.

## Requirements

### Requirement: Los videos de YouTube embebidos en un artículo se reproducen correctamente

El sistema SHALL normalizar la URL de cualquier `<iframe>` embebido en el HTML de un artículo que apunte a un dominio de YouTube (`youtube.com`, `www.youtube.com`, `youtube-nocookie.com`, `www.youtube-nocookie.com`, o `youtu.be`) antes de cargarla, de forma que el video se reproduzca sin error de configuración.

#### Scenario: Artículo con un iframe de YouTube en formato embed estándar con parámetro origin

- **WHEN** el HTML de un artículo contiene `<iframe src="https://www.youtube.com/embed/VIDEO_ID?origin=https://sitio-original.com">`
- **THEN** el video se reproduce dentro del lector, sin mostrar un error de configuración del reproductor

#### Scenario: Artículo con un iframe de YouTube en formato deprecado `/v/`

- **WHEN** el HTML de un artículo contiene `<iframe src="https://www.youtube.com/v/VIDEO_ID">`
- **THEN** el sistema lo trata como el video `VIDEO_ID` en formato embed, y el video se reproduce normalmente

#### Scenario: Artículo con un link corto de YouTube (`youtu.be`) embebido como iframe

- **WHEN** el HTML de un artículo contiene `<iframe src="https://youtu.be/VIDEO_ID">`
- **THEN** el sistema lo trata como el video `VIDEO_ID` en formato embed, y el video se reproduce normalmente

### Requirement: Los iframes que no son de YouTube no se modifican

El sistema SHALL cargar sin ninguna transformación los iframes embebidos en el HTML de un artículo cuyo dominio no sea de YouTube.

#### Scenario: Artículo con un iframe embebido de otro proveedor

- **WHEN** el HTML de un artículo contiene un `<iframe>` cuyo `src` apunta a un dominio distinto de YouTube (por ejemplo, un reproductor de podcast embebido)
- **THEN** el sistema carga esa URL tal cual, sin aplicar ninguna normalización

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
