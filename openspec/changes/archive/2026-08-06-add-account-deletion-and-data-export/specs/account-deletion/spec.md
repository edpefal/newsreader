## Purpose

Permite al usuario eliminar irreversiblemente su cuenta y todos sus datos asociados desde dentro de la app, sin depender de soporte externo, cumpliendo con el requisito de las tiendas de aplicaciones de que toda app con creación de cuenta in-app ofrezca también su borrado in-app.

## ADDED Requirements

### Requirement: Punto de entrada para eliminar la cuenta
El sistema SHALL mostrar, en el `NavigationDrawer`, una opción "Eliminar cuenta" separada de "Cerrar sesión", accesible con sesión activa.

#### Scenario: Acceso a la opción desde el drawer
- **WHEN** el usuario abre el `NavigationDrawer` con sesión activa
- **THEN** visualiza una opción "Eliminar cuenta" además de "Cerrar sesión"

---

### Requirement: Confirmación explícita antes de eliminar
El sistema SHALL mostrar una confirmación explícita que indique que la acción es irreversible y que se perderán todos los datos (fuentes, artículos con su estado, resúmenes) antes de ejecutar el borrado. El sistema NO SHALL eliminar la cuenta sin esa confirmación.

#### Scenario: Usuario cancela la confirmación
- **WHEN** el usuario toca "Eliminar cuenta" pero cancela el diálogo de confirmación
- **THEN** la cuenta y sus datos permanecen intactos, sin ningún cambio

#### Scenario: Usuario confirma la eliminación
- **WHEN** el usuario toca "Eliminar cuenta" y confirma explícitamente
- **THEN** el sistema procede con el borrado

---

### Requirement: Borrado en cascada de los datos del usuario en el servidor
El sistema SHALL, al confirmarse la eliminación, borrar del servidor todas las filas pertenecientes al usuario en `sources`, `articles` (estado de usuario) y `daily_summaries`, y SHALL eliminar al usuario de la tabla de autenticación (`auth.users`), de forma que ninguna sesión futura pueda iniciar con esas credenciales.

#### Scenario: Todas las filas del usuario se eliminan
- **WHEN** se completa el borrado de una cuenta
- **THEN** ninguna fila de `sources`, `articles` ni `daily_summaries` con ese `user_id` permanece accesible, y el usuario ya no existe en `auth.users`

#### Scenario: El borrado no afecta a otros usuarios
- **WHEN** se elimina la cuenta de un usuario
- **THEN** los datos de otras cuentas no se ven afectados

#### Scenario: Intentar iniciar sesión después de eliminar la cuenta
- **WHEN** alguien intenta iniciar sesión con las credenciales (Google/Apple) de una cuenta ya eliminada
- **THEN** el sistema lo trata como una cuenta completamente nueva, sin datos previos, en vez de recuperar la cuenta eliminada

---

### Requirement: Limpieza local y cierre de sesión tras el borrado exitoso
El sistema SHALL, tras confirmar que el borrado en el servidor se completó, limpiar todos los datos locales del dispositivo y cerrar la sesión, dejando al usuario en la pantalla de login.

#### Scenario: Estado del dispositivo tras eliminar la cuenta
- **WHEN** el borrado de cuenta se completa exitosamente
- **THEN** el dispositivo no conserva localmente ninguna fuente, artículo ni resumen de esa cuenta, y la app muestra la pantalla de login

---

### Requirement: Manejo de fallas durante el borrado
El sistema SHALL, si el borrado en el servidor falla (sin red, error del backend), mostrar un error claro al usuario y SHALL NOT limpiar los datos locales ni cerrar la sesión, dejando la cuenta y sus datos intactos para que el usuario pueda reintentar.

#### Scenario: Falla de red durante el borrado
- **WHEN** el usuario confirma la eliminación pero el dispositivo pierde conexión antes de que el servidor confirme el borrado
- **THEN** el sistema muestra un error, la cuenta permanece activa, y los datos locales no se borran
