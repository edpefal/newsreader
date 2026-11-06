## Purpose

Define el paywall de suscripción de Reevo como una pantalla propia de la app (no remota), con presentación adaptativa a teléfono, iPad y ventana de escritorio, compra y restauración de suscripciones, y la analítica del embudo de compra.

## ADDED Requirements

### Requirement: Paywall propio de la app con los planes de la tienda
El sistema SHALL mostrar un paywall construido dentro de la app que presente los planes de suscripción mensual y anual disponibles en la tienda, con el precio y el periodo formateados por la tienda para la región del usuario, y que permita comprar el plan elegido. El sistema NO SHALL escribir precios a mano en el paywall.

#### Scenario: Usuario abre el paywall
- **WHEN** un usuario sin suscripción activa abre el paywall
- **THEN** ve los planes mensual y anual con los precios que devuelve la tienda y un botón para comprar el plan seleccionado

#### Scenario: Compra completada
- **WHEN** el usuario completa la compra de un plan
- **THEN** el sistema cierra el paywall informando a quien lo abrió que el usuario ahora es suscriptor, y el estado de la app pasa a Premium

#### Scenario: Usuario cancela la compra en la hoja de Apple
- **WHEN** el usuario cancela el pago desde la hoja del sistema
- **THEN** el paywall permanece abierto, sin mostrar un error y sin conceder acceso

### Requirement: Estado de error cuando las ofertas no cargan
El sistema SHALL, cuando no pueda obtener los planes de la tienda (sin red, sin productos disponibles), mostrar en el paywall un mensaje de error con una acción "Reintentar" y SHALL NOT ofrecer botones de compra ni conceder acceso mientras las ofertas no estén cargadas.

#### Scenario: Sin conexión al abrir el paywall
- **WHEN** el usuario abre el paywall sin conexión y las ofertas no se pueden obtener
- **THEN** el paywall muestra el error con "Reintentar", sin botones de compra

#### Scenario: Reintentar con conexión
- **WHEN** el usuario toca "Reintentar" y las ofertas ahora se obtienen
- **THEN** el paywall muestra los planes y permite comprar

### Requirement: Presentación adaptativa del paywall
El sistema SHALL mostrar el paywall mediante un `PaywallLauncher` único usado por todos los puntos de entrada (Ajustes, resumen de un artículo y lector): como pantalla modal a pantalla completa cuando el ancho de la ventana es menor a 840dp, y como diálogo centrado cuando es de 840dp o más. El paywall NO SHALL asumir que es la pantalla completa ni duplicar el chrome de la pantalla que lo abre. Al cerrarse, SHALL informar a quien lo abrió si el usuario quedó suscrito.

#### Scenario: Teléfono
- **WHEN** el ancho de la ventana es menor a 840dp y se abre el paywall
- **THEN** se presenta como una pantalla modal a pantalla completa

#### Scenario: iPad o ventana ancha
- **WHEN** el ancho de la ventana es de 840dp o más y se abre el paywall
- **THEN** se presenta como un diálogo centrado, sin ocupar toda la ventana

#### Scenario: Cerrar sin comprar
- **WHEN** el usuario cierra el paywall sin haber comprado ni restaurado
- **THEN** quien lo abrió recibe que no hubo suscripción y no ejecuta la acción que dependía de ella

#### Scenario: Mismo comportamiento desde todos los puntos de entrada
- **WHEN** el paywall se abre desde Ajustes, desde el estado de cupo agotado del resumen de un artículo o desde el lector
- **THEN** se muestra el mismo paywall con el mismo flujo de compra y de cierre

### Requirement: Información legal y restauración dentro del paywall
El paywall SHALL mostrar el texto de renovación automática (que la suscripción se renueva salvo cancelación, y cuándo y cuánto se cobra tras una prueba gratis), enlaces a los Términos de Servicio y a la Política de Privacidad, y una acción "Restaurar compras". Todo el texto SHALL estar disponible en inglés, español y francés.

#### Scenario: Texto legal visible antes de comprar
- **WHEN** el usuario ve los planes en el paywall
- **THEN** el paywall muestra el texto de renovación automática y los enlaces a Términos y Privacidad antes del botón de compra

#### Scenario: Restaurar desde el paywall
- **WHEN** el usuario toca "Restaurar compras" en el paywall y tiene una suscripción activa en su Apple ID
- **THEN** el sistema restaura la suscripción, sincroniza el entitlement y cierra el paywall informando que el usuario es suscriptor

#### Scenario: Restaurar sin compras previas
- **WHEN** el usuario toca "Restaurar compras" y no tiene ninguna suscripción activa
- **THEN** el paywall le informa que no se encontraron compras y permanece abierto

### Requirement: Eventos de analítica del paywall
El sistema SHALL registrar los siguientes eventos de producto del paywall, sin PII: `paywall_viewed` con la propiedad `trigger` (`settings`, `article_summary` o `reader`); `paywall_dismissed` cuando el usuario cierra el paywall sin comprar ni restaurar; `purchase_completed` con `plan` (`monthly` o `annual`) e `is_trial` (booleano); `purchase_failed` con un código de error, sin texto libre del usuario; y `restore_completed` con un booleano que indica si se encontró una suscripción. La cancelación del pago por el usuario NO SHALL registrarse como `purchase_failed`.

#### Scenario: Abrir el paywall registra su origen
- **WHEN** el usuario abre el paywall desde Ajustes
- **THEN** el sistema registra `paywall_viewed` con `trigger = settings`

#### Scenario: Compra de la prueba anual
- **WHEN** el usuario completa la compra del plan anual con prueba gratis
- **THEN** el sistema registra `purchase_completed` con `plan = annual` e `is_trial = true`

#### Scenario: Cierre sin comprar
- **WHEN** el usuario cierra el paywall sin comprar ni restaurar
- **THEN** el sistema registra `paywall_dismissed`

#### Scenario: Cancelar el pago no es un fallo
- **WHEN** el usuario cancela el pago desde la hoja del sistema
- **THEN** el sistema no registra `purchase_failed`

#### Scenario: Fallo real de la compra
- **WHEN** la compra falla por un error de la tienda
- **THEN** el sistema registra `purchase_failed` con un código de error y sin contenido del usuario

### Requirement: Sin compras en Android
El sistema NO SHALL ofrecer compras en Android en esta versión. En Android, la app SHALL compilar y tratar al usuario como sin suscripción activa, sin intentar configurar el proveedor de compras.

#### Scenario: App en Android
- **WHEN** la app corre en Android
- **THEN** el usuario se trata como sin suscripción y el paywall no ofrece comprar
