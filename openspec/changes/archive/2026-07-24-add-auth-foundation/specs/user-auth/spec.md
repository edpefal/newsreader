## ADDED Requirements

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
