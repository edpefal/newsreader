# Capability: User Auth

## Purpose

Autenticación de usuarios de la app mediante Supabase Auth: exige una sesión activa para acceder a cualquier pantalla, permite iniciar sesión con Google o Apple, y permite cerrar sesión desde el `NavigationDrawer`.

---
## Requirements
### Requirement: Login obligatorio para acceder a la app
El sistema SHALL requerir una sesión de usuario activa para acceder a cualquier pantalla de la app (Inbox, Fuentes, Favoritos, Leídos, Resúmenes). Sin sesión activa, el sistema SHALL mostrar la pantalla de login antes que cualquier otra.

#### Scenario: Usuario abre la app sin sesión activa
- **WHEN** el usuario abre la app y no hay ninguna sesión válida persistida
- **THEN** el sistema muestra la pantalla de login, sin permitir navegar a ninguna otra pantalla

#### Scenario: Usuario intenta navegar a una ruta interna sin sesión
- **WHEN** el sistema intenta resolver cualquier ruta que no sea `/login` y no hay sesión activa
- **THEN** el sistema redirige a `/login`

#### Scenario: Usuario abre la app con sesión persistida válida
- **WHEN** el usuario abre la app y existe una sesión previamente persistida que sigue siendo válida
- **THEN** el sistema navega directamente al Inbox, sin mostrar la pantalla de login

### Requirement: Inicio de sesión con Google
El sistema SHALL permitir iniciar sesión mediante Google Sign-In, intercambiando el ID token nativo de Google por una sesión de Supabase Auth.

#### Scenario: Login exitoso con Google
- **WHEN** el usuario toca "Continuar con Google" y completa el flujo nativo de Google Sign-In exitosamente
- **THEN** el sistema crea una sesión activa y navega al Inbox

#### Scenario: Usuario cancela el flujo de Google Sign-In
- **WHEN** el usuario cancela el selector de cuenta de Google antes de completarlo
- **THEN** el sistema permanece en la pantalla de login sin mostrar un error, listo para reintentar

### Requirement: Inicio de sesión con Apple
El sistema SHALL permitir iniciar sesión mediante Sign in with Apple, intercambiando el ID token de Apple por una sesión de Supabase Auth.

#### Scenario: Login exitoso con Apple
- **WHEN** el usuario toca "Continuar con Apple" y completa el flujo nativo de Sign in with Apple exitosamente
- **THEN** el sistema crea una sesión activa y navega al Inbox

#### Scenario: Usuario cancela el flujo de Sign in with Apple
- **WHEN** el usuario cancela el flujo de Apple antes de completarlo
- **THEN** el sistema permanece en la pantalla de login sin mostrar un error, listo para reintentar

### Requirement: Cierre de sesión
El sistema SHALL permitir cerrar la sesión activa desde el `NavigationDrawer`, volviendo a la pantalla de login.

#### Scenario: Usuario cierra sesión
- **WHEN** el usuario toca "Cerrar sesión" en el `NavigationDrawer`
- **THEN** el sistema invalida la sesión activa y redirige a la pantalla de login

### Requirement: Identificación de la sesión activa en el NavigationDrawer
El sistema SHALL mostrar el email del usuario de la sesión activa en el `NavigationDrawer`, para que el usuario pueda identificar con qué cuenta está autenticado.

#### Scenario: Usuario abre el NavigationDrawer con sesión activa
- **WHEN** el usuario abre el `NavigationDrawer` con una sesión activa
- **THEN** el sistema muestra el email de esa sesión en el header del drawer

### Requirement: Alternativa ante el límite de envíos de códigos

Cuando el envío o reenvío del código de acceso por correo, o su verificación, falla porque se superó el límite de solicitudes, el sistema SHALL mostrar un mensaje localizado que, además de indicar que hay demasiadas solicitudes, ofrezca la salida: intentar más tarde o iniciar sesión con Google o Apple. El mensaje SHALL mostrarse dentro de la pantalla de login, sin salir del flujo, y el usuario SHALL poder volver a la vista inicial con las acciones de volver ya existentes para elegir Google o Apple. El mensaje SHALL estar disponible en inglés, español y francés.

#### Scenario: Límite al pedir el código

- **WHEN** el usuario pide el código con su correo y el servicio rechaza el envío por límite de solicitudes
- **THEN** el sistema muestra en el paso del correo el mensaje que sugiere intentar más tarde o entrar con Google o Apple
- **AND** el usuario permanece en la pantalla de login

#### Scenario: Límite al reenviar el código

- **WHEN** el usuario pide reenviar el código y el servicio rechaza el envío por límite de solicitudes
- **THEN** el sistema muestra en el paso del código el mismo mensaje con la alternativa de Google o Apple

#### Scenario: Volver y elegir otro método

- **WHEN** el usuario ve el mensaje de límite en cualquier paso del flujo de correo y vuelve atrás hasta la vista inicial
- **THEN** el sistema muestra de nuevo los botones de Google y Apple, que siguen funcionando con normalidad

#### Scenario: Mensaje en cada idioma

- **WHEN** el idioma de la app es inglés, español o francés
- **THEN** el mensaje de límite de solicitudes se muestra en ese idioma con la misma sugerencia de alternativa

### Requirement: Inicio de sesión con correo y código
El sistema SHALL permitir iniciar sesión con un correo electrónico y un código de un solo uso de 6 dígitos enviado a ese correo. La pantalla de login SHALL ofrecer esta opción como una alternativa secundaria a Google y Apple (un botón de texto "Continuar con correo", separado de los botones sociales). El flujo SHALL tener dos pasos dentro de la pantalla de login: ingresar el correo y, una vez enviado el código, ingresar el código. El código SHALL ser válido durante 10 minutos. Si el correo no tiene una cuenta, el sistema SHALL crearla automáticamente al verificar el código, sin una pantalla de registro aparte. Un correo que ya tiene cuenta por Google o Apple con el mismo correo verificado SHALL entrar a esa misma cuenta.

La vista donde se ingresa el correo SHALL mostrar un aviso para quien entró antes con Apple o Google, indicando que debe usar ese mismo método para ver sus datos. El campo del código SHALL poder autocompletarse con el código recibido por correo en dispositivos que lo soporten. El formulario SHALL mantener el ancho máximo del resto de la pantalla de login. Todo texto SHALL estar disponible en inglés, español y francés.

#### Scenario: La pantalla de login ofrece los tres métodos
- **WHEN** el usuario sin sesión abre la pantalla de login
- **THEN** ve los botones de Google y Apple y, debajo de un separador, la opción "Continuar con correo"

#### Scenario: Login exitoso con correo y código
- **WHEN** el usuario toca "Continuar con correo", escribe un correo válido, recibe el código y lo escribe correctamente
- **THEN** el sistema crea una sesión activa y navega al Inbox

#### Scenario: Correo sin cuenta previa
- **WHEN** el usuario completa el flujo con un correo que no tiene cuenta
- **THEN** el sistema crea la cuenta y entra al Inbox, sin pedir ningún registro adicional

#### Scenario: Mismo correo que una cuenta de Google o Apple
- **WHEN** el usuario completa el flujo con un correo que ya tiene cuenta creada con Google o Apple usando ese mismo correo
- **THEN** el sistema entra a esa cuenta existente, con sus mismos datos

#### Scenario: Aviso para quien entró antes con Apple o Google
- **WHEN** el usuario abre la vista donde se ingresa el correo
- **THEN** ve un aviso que le indica que, si entró antes con Apple o Google, use ese mismo método para ver sus datos

#### Scenario: Volver desde el paso del código
- **WHEN** el usuario está en el paso del código y usa el botón atrás del sistema o la opción de cambiar el correo
- **THEN** el sistema vuelve al paso de ingresar el correo sin cerrar la pantalla de login

#### Scenario: Volver desde el paso del correo
- **WHEN** el usuario está en el paso de ingresar el correo y vuelve atrás
- **THEN** el sistema regresa a la vista inicial de la pantalla de login con Google y Apple

### Requirement: Reenvío del código de acceso
El sistema SHALL permitir pedir un nuevo código desde el paso del código, pero solo después de 60 segundos desde el último envío. Mientras tanto, la opción de reenviar SHALL mostrarse deshabilitada con el tiempo restante. Al reenviarse un código, el contador SHALL reiniciarse.

#### Scenario: Reenvío no disponible durante el contador
- **WHEN** el usuario acaba de recibir un código y aún no pasan 60 segundos
- **THEN** la opción de reenviar está deshabilitada y muestra los segundos restantes

#### Scenario: Reenvío disponible al terminar el contador
- **WHEN** pasaron 60 segundos desde el último envío
- **THEN** la opción de reenviar se habilita, y al tocarla el sistema envía un nuevo código y reinicia el contador

### Requirement: Errores del inicio de sesión con correo
El sistema SHALL informar con un mensaje localizado, sin salir de la pantalla de login, cuando el correo no es válido, el código es incorrecto o expiró, o se superó el límite de envíos o intentos. Un error de red SHALL mostrar el mensaje de error de conexión existente. Tras un error, el usuario SHALL poder corregir el dato y reintentar.

#### Scenario: Correo con formato inválido
- **WHEN** el usuario intenta enviar un correo con formato inválido
- **THEN** el sistema muestra un mensaje de correo inválido y no envía ningún código

#### Scenario: Código incorrecto o expirado
- **WHEN** el usuario escribe un código incorrecto, o uno que ya expiró
- **THEN** el sistema muestra un mensaje de código inválido o expirado, permanece en el paso del código y permite reintentar o pedir uno nuevo

#### Scenario: Demasiados envíos o intentos
- **WHEN** el servidor rechaza una solicitud por exceso de envíos o intentos
- **THEN** el sistema muestra un mensaje indicando que espere antes de reintentar

### Requirement: Registro del inicio de sesión con correo
El sistema SHALL registrar el evento de producto `login_completed` con la propiedad `method` igual a `email` cuando el usuario completa el inicio de sesión con correo y código. Un intento fallido o abandonado NO SHALL registrar ese evento.

#### Scenario: Login con correo completado
- **WHEN** el usuario verifica el código correctamente y se crea la sesión
- **THEN** el sistema registra `login_completed` con `method` igual a `email`

#### Scenario: Código incorrecto no registra el evento
- **WHEN** el usuario escribe un código incorrecto
- **THEN** el sistema no registra `login_completed`

