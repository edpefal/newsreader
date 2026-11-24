# Capability: Account Deletion

## Purpose

Permite al usuario eliminar irreversiblemente su cuenta y todos sus datos asociados desde dentro de la app, sin depender de soporte externo, cumpliendo con el requisito de las tiendas de aplicaciones de que toda app con creación de cuenta in-app ofrezca también su borrado in-app.

## Requirements

### Requirement: Punto de entrada para eliminar la cuenta
El sistema SHALL mostrar, en la pantalla de Configuración (Settings), una opción "Eliminar cuenta" separada de "Cerrar sesión", accesible con sesión activa.

#### Scenario: Acceso a la opción desde Configuración
- **WHEN** el usuario abre la pantalla de Configuración con sesión activa
- **THEN** visualiza una opción "Eliminar cuenta"

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

### Requirement: Aviso sobre la suscripción activa al eliminar la cuenta
El sistema SHALL, cuando el usuario con una suscripción activa inicia la eliminación de su cuenta, indicar en la confirmación que eliminar la cuenta no cancela la suscripción de Apple y que debe cancelarla desde los ajustes de su Apple ID para no seguir siendo cobrado, ofreciendo una acción que abra la página de gestión de suscripciones de Apple. El aviso NO SHALL mostrarse a usuarios sin suscripción activa y NO SHALL impedir ni condicionar el borrado.

#### Scenario: Usuario suscrito inicia el borrado
- **WHEN** un usuario con suscripción activa toca "Eliminar cuenta"
- **THEN** la confirmación incluye el aviso de que la suscripción no se cancela y una acción para gestionarla

#### Scenario: Usuario sin suscripción no ve el aviso
- **WHEN** un usuario sin suscripción activa toca "Eliminar cuenta"
- **THEN** la confirmación no menciona ninguna suscripción

#### Scenario: El aviso no bloquea el borrado
- **WHEN** un usuario suscrito ve el aviso y confirma la eliminación sin gestionar la suscripción
- **THEN** el sistema procede con el borrado de la cuenta

### Requirement: Borrado del cliente en RevenueCat
El sistema SHALL, al eliminar una cuenta, solicitar a RevenueCat el borrado del cliente asociado al `user_id` de esa cuenta. Si esa solicitud falla, el sistema SHALL registrar el error en la observabilidad sin incluir PII y NO SHALL impedir ni revertir el borrado de la cuenta.

#### Scenario: Cuenta eliminada sin dejar el cliente en RevenueCat
- **WHEN** se completa el borrado de una cuenta
- **THEN** el cliente de ese `user_id` es eliminado de RevenueCat

#### Scenario: Falla el borrado en RevenueCat
- **WHEN** la solicitud de borrado a RevenueCat falla durante la eliminación de una cuenta
- **THEN** el error queda registrado, y la cuenta y sus datos se eliminan igualmente
