## MODIFIED Requirements

### Requirement: Inicio de sesión con correo y código
El sistema SHALL permitir iniciar sesión con un correo electrónico y un código de un solo uso de 6 dígitos enviado a ese correo. La pantalla de login SHALL ofrecer esta opción como una alternativa secundaria a Google y Apple (un botón de texto "Continuar con correo", separado de los botones sociales) **únicamente cuando el feature flag `email-login` esté activo**; con el flag apagado o sin resolver, la pantalla SHALL mostrar solo Google y Apple, sin el separador ni el botón de correo. Google y Apple SHALL mostrarse siempre, sin depender de ningún flag. El flujo SHALL tener dos pasos dentro de la pantalla de login: ingresar el correo y, una vez enviado el código, ingresar el código. El código SHALL ser válido durante 10 minutos. Si el correo no tiene una cuenta, el sistema SHALL crearla automáticamente al verificar el código, sin una pantalla de registro aparte. Un correo que ya tiene cuenta por Google o Apple con el mismo correo verificado SHALL entrar a esa misma cuenta.

El flag solo decide si se ofrece la entrada al flujo: un usuario que ya está dentro del flujo de correo (ingresando el correo o el código) NO SHALL ser expulsado de él si el flag se apaga mientras tanto. La vista donde se ingresa el correo SHALL mostrar un aviso para quien entró antes con Apple o Google, indicando que debe usar ese mismo método para ver sus datos. El campo del código SHALL poder autocompletarse con el código recibido por correo en dispositivos que lo soporten. El formulario SHALL mantener el ancho máximo del resto de la pantalla de login. Todo texto SHALL estar disponible en inglés, español y francés.

#### Scenario: La pantalla de login ofrece los tres métodos con el flag activo
- **WHEN** el usuario sin sesión abre la pantalla de login y el flag `email-login` está activo
- **THEN** ve los botones de Google y Apple y, debajo de un separador, la opción "Continuar con correo"

#### Scenario: La pantalla de login con el flag apagado
- **WHEN** el usuario sin sesión abre la pantalla de login y el flag `email-login` está apagado o no se ha resuelto
- **THEN** ve únicamente los botones de Google y Apple, sin separador ni opción de correo

#### Scenario: El flag se activa con la pantalla ya visible
- **WHEN** la pantalla de login está visible con solo Google y Apple y el flag `email-login` pasa a activo
- **THEN** la pantalla muestra el separador y la opción "Continuar con correo" sin que el usuario deba reiniciar la app

#### Scenario: El flag se apaga con el flujo de correo en curso
- **WHEN** el usuario está ingresando su correo o el código y el flag `email-login` pasa a apagado
- **THEN** el usuario puede completar el flujo sin ser expulsado, y al volver a la vista inicial ya no ve la opción de correo

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
