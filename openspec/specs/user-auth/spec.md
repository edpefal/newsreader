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

