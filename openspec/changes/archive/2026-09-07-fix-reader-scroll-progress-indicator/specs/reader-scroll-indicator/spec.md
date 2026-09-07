## MODIFIED Requirements

### Requirement: Indicador visual de progreso de scroll en el lector
La pantalla de lectura de un artículo (`ReaderScreen`) SHALL mostrar una barra de progreso vertical que refleja la posición relativa del usuario dentro del contenido del artículo, cuando el contenido excede el alto del viewport visible, y SHALL reevaluar esta condición cada vez que el alto total del contenido cambie, incluyendo después de que elementos que cargan de forma asíncrona (imágenes remotas, embeds, WebViews de newsletters) terminen de ajustar su tamaño.

#### Scenario: Contenido más largo que el viewport
- **WHEN** el usuario abre un artículo cuyo contenido renderizado excede el alto de la pantalla
- **THEN** se muestra una barra de progreso vertical en la pantalla de lectura

#### Scenario: Contenido que cabe completamente en el viewport
- **WHEN** el usuario abre un artículo cuyo contenido renderizado no excede el alto de la pantalla (no hay scroll posible)
- **THEN** la barra de progreso no se muestra

#### Scenario: Contenido crece después del primer frame por carga asíncrona
- **WHEN** el usuario abre un artículo que en el primer frame cabe completamente en el viewport, pero cuyo contenido crece luego de que una imagen remota, un embed o un WebView de newsletter termina de cargar y supera el alto de la pantalla
- **THEN** la barra de progreso pasa a mostrarse, reflejando la nueva proporción de contenido visible, sin requerir que el usuario haga scroll primero

#### Scenario: Contenido se reduce después del primer frame
- **WHEN** el alto total del contenido de un artículo, inicialmente mayor al viewport, se recalcula y ya no excede el alto de la pantalla
- **THEN** la barra de progreso deja de mostrarse

## ADDED Requirements

### Requirement: No agregar dependencias de scroll fuera de la pantalla de lectura
El recálculo de progreso y visibilidad ante cambios de alto del contenido SHALL implementarse íntegramente sobre el `ScrollController`/`Scrollable` ya usado en `ReaderScreen`, sin introducir temporizadores de sondeo (`polling`) fijos para detectar cambios de tamaño.

#### Scenario: Cambio de alto detectado sin polling
- **WHEN** el contenido del artículo cambia de alto en cualquier momento después de la carga inicial
- **THEN** el indicador se actualiza a partir de una notificación de métricas de scroll, no de un timer que revise el tamaño en intervalos fijos
