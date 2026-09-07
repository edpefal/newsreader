# Spec: Reader Scroll Indicator

## Purpose

Dar al usuario una referencia visual de su posición dentro de un artículo largo mientras lee, sin interferir con el comportamiento existente de la pantalla de lectura (`ReaderScreen`).

## Requirements

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

### Requirement: Actualización en tiempo real del progreso de scroll
La barra de progreso SHALL reflejar, en todo momento, la posición actual de scroll como una proporción entre el inicio (0%) y el final (100%) del contenido.

#### Scenario: Usuario en el inicio del artículo
- **WHEN** el usuario abre el artículo y no ha hecho scroll
- **THEN** la barra de progreso se muestra en su posición inicial (0%)

#### Scenario: Usuario hace scroll manual
- **WHEN** el usuario desplaza el contenido hacia abajo
- **THEN** la barra de progreso avanza proporcionalmente a la posición actual de scroll respecto al contenido total

#### Scenario: Usuario llega al final del artículo
- **WHEN** el usuario hace scroll hasta el final del contenido
- **THEN** la barra de progreso se muestra en su posición final (100%)

### Requirement: El indicador no interfiere con la funcionalidad existente del lector
La adición del indicador de progreso SHALL preservar el comportamiento existente de la pantalla de lectura: marcar el artículo como leído al abrirlo, alternar favorito, y navegar a la vista web del artículo.

#### Scenario: Artículo se marca como leído normalmente
- **WHEN** el usuario abre un artículo desde el inbox, archivo o favoritos
- **THEN** el artículo se marca como leído igual que antes de agregar el indicador de progreso

#### Scenario: Alternar favorito sigue funcionando
- **WHEN** el usuario presiona el botón de favorito en la pantalla de lectura
- **THEN** el estado de favorito del artículo cambia igual que antes de agregar el indicador de progreso

### Requirement: No agregar dependencias de scroll fuera de la pantalla de lectura
El recálculo de progreso y visibilidad ante cambios de alto del contenido SHALL implementarse íntegramente sobre el `ScrollController`/`Scrollable` ya usado en `ReaderScreen`, sin introducir temporizadores de sondeo (`polling`) fijos para detectar cambios de tamaño.

#### Scenario: Cambio de alto detectado sin polling
- **WHEN** el contenido del artículo cambia de alto en cualquier momento después de la carga inicial
- **THEN** el indicador se actualiza a partir de una notificación de métricas de scroll, no de un timer que revise el tamaño en intervalos fijos
</content>
