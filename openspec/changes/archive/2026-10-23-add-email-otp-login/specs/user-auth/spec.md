## ADDED Requirements

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
