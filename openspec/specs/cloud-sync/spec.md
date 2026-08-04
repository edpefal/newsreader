# Capability: Cloud Sync

## Purpose

Sincronización bidireccional de fuentes, resúmenes diarios y estado de usuario sobre artículos (leído/favorito/borrado) entre dispositivos de la misma cuenta, vía Postgres/Supabase. Sin tiempo real: se dispara al abrir la app, en pull-to-refresh, al volver del background, y al iniciar sesión.

---

## Requirements

### Requirement: Sincronización bidireccional al abrir la app
El sistema SHALL sincronizar fuentes, resúmenes diarios y el estado de usuario sobre artículos (`isRead`/`isFavorite`/`deletedAt`) entre el dispositivo y la nube (Postgres/Supabase) al abrir la app, subiendo los cambios locales pendientes y bajando los cambios remotos en una sola operación. El contenido de los artículos (título, extracto, HTML, etc.) SHALL sincronizarse solo en sentido servidor→dispositivo (pull), nunca subido por el cliente — los artículos nacen en el servidor vía fetch centralizado de feeds (ver capability `feed-polling`).

#### Scenario: Marcar un artículo como leído se refleja en otro dispositivo
- **WHEN** el usuario marca un artículo como leído en el dispositivo A, y luego abre la app en el dispositivo B (misma cuenta)
- **THEN** el artículo aparece como leído en el dispositivo B, sin necesidad de ninguna acción manual además de abrir/refrescar la app

#### Scenario: Agregar una fuente se refleja en otro dispositivo
- **WHEN** el usuario agrega una fuente en el dispositivo A, y luego abre la app en el dispositivo B
- **THEN** la fuente aparece en la lista de fuentes del dispositivo B

#### Scenario: Sin sincronización en tiempo real
- **WHEN** el usuario marca un artículo como leído en el dispositivo A mientras el dispositivo B está con la app abierta en ese mismo momento
- **THEN** el dispositivo B NO refleja el cambio hasta que el usuario vuelva a abrir la app o haga pull-to-refresh — no hay actualización automática en vivo

---

### Requirement: Detección de cambios locales sin cola separada
El sistema SHALL detectar qué registros locales cambiaron desde la última sincronización comparando el campo `updatedAt` de cada registro contra el cursor de última sincronización, sin depender de una cola/outbox explícita de mutaciones.

#### Scenario: Solo se suben los registros modificados
- **WHEN** se ejecuta una sincronización y hay artículos cuyo `updatedAt` es anterior al cursor de última sincronización
- **THEN** esos artículos NO se vuelven a subir a la nube, solo los que cambiaron después del cursor

---

### Requirement: Borrados propagados vía soft-delete
El sistema SHALL marcar los registros borrados con un timestamp `deletedAt` en lugar de borrarlos físicamente de inmediato, y SHALL borrarlos físicamente en el dispositivo local recién al recibir la confirmación (vía sincronización) de que el borrado ya se conoce.

#### Scenario: Eliminar una fuente se propaga a otro dispositivo
- **WHEN** el usuario elimina una fuente en el dispositivo A, y luego el dispositivo B sincroniza
- **THEN** la fuente y sus artículos asociados desaparecen también del dispositivo B

---

### Requirement: Resolución de conflictos por last-write-wins
El sistema SHALL resolver cualquier conflicto entre un cambio local y uno remoto para el mismo registro usando el `updatedAt` más reciente, sin ningún mecanismo de merge adicional.

#### Scenario: Favorito togglado en dos dispositivos mientras ambos estaban offline
- **WHEN** el usuario marca un artículo como favorito en el dispositivo A y lo desmarca en el dispositivo B mientras ambos están sin conexión, y luego ambos sincronizan
- **THEN** el estado final del artículo es el del cambio con el `updatedAt` más reciente entre los dos, sin combinar ambos cambios

---

### Requirement: Primer login sube los datos locales existentes
El sistema SHALL, en la primera sincronización de un dispositivo (sin cursor de sincronización previo), subir todos los registros locales existentes de fuentes y resúmenes diarios a la nube como estado inicial, sin descartarlos. Para artículos, el primer sync SHALL subir únicamente el estado de usuario (`isRead`/`isFavorite`/`deletedAt`) de artículos que el servidor ya conoce (por `id`) — nunca crear artículos nuevos ni subir su contenido desde el cliente.

#### Scenario: Usuario ya tenía fuentes locales antes de este change
- **WHEN** un dispositivo con fuentes ya guardadas localmente sincroniza por primera vez
- **THEN** esas fuentes se suben a la nube en vez de perderse o quedar fuera de la cuenta

#### Scenario: Usuario ya tenía artículos marcados como leídos localmente
- **WHEN** un dispositivo con artículos locales (creados antes de este change) sincroniza por primera vez
- **THEN** el sistema no sube esos artículos como registros nuevos — solo se propaga el estado de lectura/favorito de los artículos que el servidor reconoce por `id`

---

### Requirement: Sincronización automática al iniciar sesión
El sistema SHALL disparar una sincronización completa al detectar la transición de sin-sesión a con-sesión (primer login, o login después de cerrar sesión), sin esperar a que el usuario haga pull-to-refresh manualmente. Mientras la sincronización está en curso, el sistema SHALL mostrar un indicador de carga visible con un mensaje que comunique qué está pasando.

#### Scenario: Login después de cerrar sesión
- **WHEN** el usuario cierra sesión (los datos locales se limpian) y vuelve a iniciar sesión con la misma cuenta
- **THEN** el Inbox y la lista de fuentes se poblán automáticamente con los datos de la nube, mostrando un indicador de carga mientras la sincronización está en curso

---

### Requirement: Indicador de progreso visible durante la sincronización al volver del background
El sistema SHALL mostrar un indicador de progreso no bloqueante (`LinearProgressIndicator` debajo del `AppBar` del Inbox) mientras la sincronización disparada al volver del background está en curso, sin ocultar ni reemplazar los artículos ya cargados en pantalla. El indicador SHALL desaparecer automáticamente al terminar la sincronización, tanto si finaliza con éxito como con error.

#### Scenario: Volver del background con el Inbox ya cargado
- **WHEN** el usuario tiene el Inbox con artículos visibles, manda la app a segundo plano, y vuelve a traerla a primer plano
- **THEN** aparece un `LinearProgressIndicator` debajo del título mientras la sincronización está en curso, y los artículos ya cargados siguen visibles sin interrupción

#### Scenario: La sincronización termina
- **WHEN** la sincronización disparada por el resume termina (con o sin artículos nuevos)
- **THEN** el indicador de progreso desaparece y, si hubo cambios, el Inbox se actualiza con el contenido nuevo

---

### Requirement: Acceso a los datos sincronizados restringido por usuario
El sistema SHALL restringir el acceso a las tablas de sincronización (`sources`, `articles`, `daily_summaries`) mediante Row-Level Security, de forma que un usuario solo pueda leer o escribir sus propios registros.

#### Scenario: Un usuario no puede leer datos de otro usuario
- **WHEN** un usuario autenticado intenta leer directamente la tabla `articles` de Postgres
- **THEN** solo recibe las filas cuyo `user_id` coincide con su propio `auth.uid()`, nunca las de otro usuario

---

### Requirement: Push inmediato del estado "leído" de un artículo
El sistema SHALL intentar subir el estado (`isRead`, `readAt`, `updatedAt`) de un artículo a Supabase inmediatamente al marcarlo como leído, sin esperar al próximo trigger de sincronización completa (login, resume, o pull-to-refresh). Este push SHALL ser best-effort: no SHALL bloquear ni retrasar la actualización local del artículo ni la actualización de la interfaz, y cualquier falla (sin red, error del servidor) SHALL ignorarse silenciosamente sin propagarse a la interfaz. El push SHALL intentarse únicamente si hay una sesión de usuario activa.

#### Scenario: Marcar como leído con conexión disponible
- **WHEN** el usuario marca un artículo como leído y el dispositivo tiene conexión
- **THEN** el estado `isRead=true` se sube a Supabase sin que el usuario tenga que abrir la app de nuevo, hacer pull-to-refresh, o esperar a que la app pase a background y vuelva

#### Scenario: Marcar como leído sin conexión
- **WHEN** el usuario marca un artículo como leído sin conexión a internet
- **THEN** la actualización local (Hive) se completa igual, sin errores visibles para el usuario, y el estado queda pendiente de subir en la próxima sincronización completa

#### Scenario: Marcar como leído sin sesión activa
- **WHEN** el usuario marca un artículo como leído sin haber iniciado sesión
- **THEN** el sistema no intenta ningún push a la nube, y la actualización local se completa igual

#### Scenario: El push inmediato no retrasa la interacción del usuario
- **WHEN** el usuario marca un artículo como leído
- **THEN** la interfaz refleja el artículo como leído sin esperar la respuesta de red del push a la nube

#### Scenario: Falla el push inmediato pero la sincronización completa lo repara
- **WHEN** el push inmediato de un artículo falla (por ejemplo, por falta de conexión) y luego el dispositivo dispara una sincronización completa (login, resume, o pull-to-refresh)
- **THEN** el estado `isRead=true` de ese artículo se sube a la nube en esa sincronización completa, igual que cualquier otro cambio local pendiente

---

### Requirement: El borrado de una fuente cascada a sus artículos del lado del servidor
El sistema SHALL marcar como borrados (`deleted_at`), del lado del servidor y en la misma operación que borra la fuente, todos los artículos de esa fuente pertenecientes al mismo usuario, excepto los que estén marcados como favoritos. Esta garantía SHALL cumplirse sin depender de que el cliente propague individualmente el estado de cada artículo.

#### Scenario: Se elimina una fuente con artículos no favoritos
- **WHEN** el cliente propaga el borrado de una fuente al servidor
- **THEN** todos los artículos de esa fuente que no sean favoritos quedan marcados como borrados en el servidor, sin que el cliente tenga que enviar el estado de cada artículo individualmente

#### Scenario: Se elimina una fuente con artículos favoritos
- **WHEN** el cliente propaga el borrado de una fuente que tiene artículos marcados como favoritos
- **THEN** esos artículos favoritos permanecen sin marcar como borrados en el servidor

#### Scenario: El cliente se cierra antes de terminar de propagar el estado de los artículos
- **WHEN** el cliente propaga el borrado de la fuente pero la app se cierra o pierde conexión antes de intentar propagar el estado de sus artículos individualmente
- **THEN** los artículos de esa fuente (no favoritos) igual quedan marcados como borrados en el servidor, y cualquier dispositivo que sincronice después dejará de verlos
