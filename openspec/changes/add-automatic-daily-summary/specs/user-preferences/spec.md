## Purpose

Persistir en la nube el locale activo y el offset horario UTC del dispositivo de cada usuario, para que procesos del lado del servidor sin sesión de usuario en vivo (como la generación automática del resumen diario) sepan en qué idioma y a qué hora local corresponde actuar para ese usuario.

## ADDED Requirements

### Requirement: Sincronización del locale y offset horario del dispositivo
El sistema SHALL persistir, por usuario, el locale activo de la app (uno de los soportados por `AppLocalizations`: inglés, español o francés) y el offset horario actual del dispositivo respecto a UTC, en minutos. El cliente SHALL actualizar estos valores en cada ciclo de sincronización con la nube, reflejando el estado actual del dispositivo en ese momento (no un valor fijado una sola vez al crear la cuenta).

#### Scenario: Primera sincronización de un usuario nuevo
- **WHEN** un usuario sincroniza por primera vez después de crear su cuenta
- **THEN** el sistema persiste su locale activo y su offset horario actual en la nube

#### Scenario: El usuario cambia el idioma del dispositivo
- **WHEN** el usuario cambia el idioma del sistema operativo (o de la app, si hay un selector propio) a uno de los soportados, y vuelve a sincronizar
- **THEN** el sistema actualiza el locale persistido con el nuevo valor

#### Scenario: El usuario viaja a una zona horaria distinta
- **WHEN** el offset horario del dispositivo del usuario cambia (viaje, cambio de horario de verano) y el dispositivo vuelve a sincronizar
- **THEN** el sistema actualiza el offset horario persistido con el nuevo valor

### Requirement: Valor por defecto antes de la primera sincronización
El sistema SHALL tratar a un usuario sin ninguna preferencia sincronizada todavía como si tuviera locale inglés y offset horario UTC+0, sin bloquear ni fallar ningún proceso que dependa de estos valores.

#### Scenario: Usuario sin preferencias sincronizadas
- **WHEN** un proceso del servidor necesita el locale o el offset horario de un usuario que todavía no sincronizó ninguna preferencia
- **THEN** el sistema usa inglés y UTC+0 como default, sin error

### Requirement: Solo el propio usuario puede leer o modificar sus preferencias
El sistema SHALL restringir la lectura y escritura de las preferencias de un usuario a ese mismo usuario autenticado, salvo procesos internos del servidor que operan con privilegios elevados (ej. la generación automática del resumen diario).

#### Scenario: Usuario intenta leer las preferencias de otra cuenta
- **WHEN** un usuario autenticado intenta consultar las preferencias de un `user_id` distinto al suyo
- **THEN** el sistema no devuelve esos datos
