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

Una vez completada esa sincronización inicial y mostrado el Inbox, el sistema SHALL disparar además, en segundo plano y sin bloquear la interfaz, un fetch de feeds equivalente al de pull-to-refresh (ver capability `feed-polling`), para traer contenido más reciente que el que ya había en la nube. Mientras ese fetch en segundo plano está en curso, el sistema SHALL mostrar el mismo indicador no invasivo usado para la sincronización al volver del background, sin ocultar ni reemplazar el contenido ya visible. Cualquier error de ese fetch en segundo plano (red, fuentes fallidas) SHALL manejarse en silencio, sin mostrar ningún mensaje de error al usuario. Al terminar, el sistema SHALL volver a sincronizar el estado y recargar el Inbox si hay contenido nuevo.

#### Scenario: Login después de cerrar sesión
- **WHEN** el usuario cierra sesión (los datos locales se limpian) y vuelve a iniciar sesión con la misma cuenta
- **THEN** el Inbox y la lista de fuentes se poblán automáticamente con los datos de la nube, mostrando un indicador de carga mientras la sincronización está en curso

#### Scenario: Fetch de feeds en segundo plano tras el login
- **WHEN** la sincronización inicial de login termina y el Inbox ya muestra artículos
- **THEN** el sistema dispara automáticamente un fetch de feeds en segundo plano, mostrando un indicador no invasivo mientras está en curso, sin reemplazar los artículos ya visibles

#### Scenario: El fetch en segundo plano encuentra artículos nuevos
- **WHEN** el fetch de feeds disparado tras el login encuentra artículos más recientes que los que ya había en la nube
- **THEN** el Inbox se actualiza automáticamente con esos artículos al terminar el fetch, sin que el usuario tenga que hacer pull-to-refresh manualmente

#### Scenario: El fetch en segundo plano falla
- **WHEN** el fetch de feeds disparado tras el login falla (sin conexión, error de red, o alguna fuente no responde)
- **THEN** el sistema no muestra ningún mensaje de error al usuario; el Inbox permanece con el contenido que ya tenía cargado

---

### Requirement: Indicador de progreso visible durante la sincronización al volver del background
El sistema SHALL mostrar un indicador de progreso no bloqueante (`LinearProgressIndicator` debajo del `AppBar` del Inbox) mientras la sincronización disparada al volver del background, o el fetch de feeds en segundo plano tras el login, está en curso, sin ocultar ni reemplazar los artículos ya cargados en pantalla. El indicador SHALL desaparecer automáticamente al terminar la sincronización, tanto si finaliza con éxito como con error.

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

### Requirement: Push inmediato del estado "favorito" de un artículo
El sistema SHALL intentar subir el estado (`isFavorite`, `savedAsFavoriteAt`, `updatedAt`) de un artículo a Supabase inmediatamente al marcarlo o desmarcarlo como favorito, sin esperar al próximo trigger de sincronización completa (login, resume, o pull-to-refresh). Este push SHALL ser best-effort: no SHALL bloquear ni retrasar la actualización local del artículo ni la actualización de la interfaz, y cualquier falla (sin red, error del servidor) SHALL ignorarse silenciosamente sin propagarse a la interfaz. El push SHALL intentarse únicamente si hay una sesión de usuario activa.

#### Scenario: Marcar como favorito con conexión disponible
- **WHEN** el usuario marca un artículo como favorito y el dispositivo tiene conexión
- **THEN** el estado `isFavorite=true` se sube a Supabase sin que el usuario tenga que abrir la app de nuevo, hacer pull-to-refresh, o esperar a que la app pase a background y vuelva

#### Scenario: Desmarcar un favorito con conexión disponible
- **WHEN** el usuario desmarca un artículo que era favorito y el dispositivo tiene conexión
- **THEN** el estado `isFavorite=false` se sube a Supabase de la misma forma inmediata

#### Scenario: Marcar como favorito sin conexión
- **WHEN** el usuario marca un artículo como favorito sin conexión a internet
- **THEN** la actualización local (Hive) se completa igual, sin errores visibles para el usuario, y el estado queda pendiente de subir en la próxima sincronización completa

#### Scenario: Marcar como favorito sin sesión activa
- **WHEN** el usuario marca un artículo como favorito sin haber iniciado sesión
- **THEN** el sistema no intenta ningún push a la nube, y la actualización local se completa igual

#### Scenario: El push inmediato no retrasa la interacción del usuario
- **WHEN** el usuario marca o desmarca un artículo como favorito
- **THEN** la interfaz refleja el nuevo estado sin esperar la respuesta de red del push a la nube

#### Scenario: Falla el push inmediato pero la sincronización completa lo repara
- **WHEN** el push inmediato de un artículo favorito falla (por ejemplo, por falta de conexión) y luego el dispositivo dispara una sincronización completa (login, resume, o pull-to-refresh)
- **THEN** el estado `isFavorite` de ese artículo se sube a la nube en esa sincronización completa, igual que cualquier otro cambio local pendiente

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

---

### Requirement: Sincronización de daily_summaries incluye la agrupación por fuente
La tabla remota `daily_summaries` SHALL incluir una columna para la agrupación por fuente del resumen (identificador y nombre de cada fuente, e ids de sus artículos de ese día). Al subir cambios locales de `daily_summaries`, el sistema SHALL incluir esta agrupación en la fila enviada. Al bajar cambios remotos, el sistema SHALL reconstruir esta agrupación a partir de esa columna.

#### Scenario: Subir un resumen incluye su agrupación por fuente
- **WHEN** el sistema sube un `DailySummary` local que tiene agrupación por fuente hacia `daily_summaries`
- **THEN** la fila enviada incluye esa agrupación por fuente completa

#### Scenario: Bajar un resumen reconstruye su agrupación por fuente
- **WHEN** el sistema baja un cambio de `daily_summaries` que incluye la columna de agrupación por fuente
- **THEN** el sistema reconstruye el `DailySummary` local con esa misma agrupación por fuente

---

### Requirement: Errores de sincronización con la nube se clasifican y no dejan la interfaz colgada
El sistema SHALL clasificar cualquier error que ocurra al sincronizar con la nube (subida, bajada, o ambas) usando el mismo mecanismo de `AppErrorCode` que el resto de los errores de red de la app, en lugar de una excepción sin código asociado. Todo punto de la interfaz que dispare una sincronización completa SHALL capturar ese error y transicionar a un estado terminal (no un estado de carga indefinido), sin importar si el error se muestra al usuario o se maneja en silencio según el flujo correspondiente.

#### Scenario: Falla la sincronización al entrar al detalle de una fuente recién agregada
- **WHEN** la sincronización que se dispara al entrar al detalle de una fuente inmediatamente después de agregarla falla por cualquier motivo (sin red, error del servidor, timeout)
- **THEN** la pantalla de detalle deja de mostrar el indicador de carga y muestra los artículos disponibles localmente (potencialmente ninguno), en vez de quedarse cargando indefinidamente

#### Scenario: Falla la sincronización disparada al iniciar sesión
- **WHEN** la sincronización completa que se dispara al detectar la transición de sin-sesión a con-sesión falla
- **THEN** el sistema transiciona a un estado que refleje el error en vez de quedarse en el indicador de carga inicial indefinidamente

#### Scenario: Falla la sincronización disparada al volver del background
- **WHEN** la sincronización que se dispara al volver la app a primer plano falla
- **THEN** el indicador de progreso no invasivo desaparece y el Inbox conserva el contenido que ya tenía cargado, sin quedar en estado de carga permanente

---

### Requirement: Timeout explícito en las llamadas de sincronización con la nube
El sistema SHALL aplicar un timeout explícito a cada llamada de sincronización con la nube (subida y bajada de fuentes, artículos y resúmenes diarios), de forma que una llamada que no responde falle con un error clasificado como timeout en lugar de quedar pendiente indefinidamente.

#### Scenario: Una llamada de sincronización no responde
- **WHEN** una llamada de subida o bajada de datos hacia la nube no recibe respuesta dentro del tiempo de espera configurado
- **THEN** la llamada falla con un error clasificado como timeout, permitiendo que el caller lo maneje igual que cualquier otro error de sincronización

---

### Requirement: Invocaciones concurrentes de la sincronización completa se deduplican
El sistema SHALL evitar que dos invocaciones solapadas de la sincronización completa (subida y bajada de fuentes, artículos y resúmenes diarios) se ejecuten en paralelo de forma independiente: una invocación que empieza mientras otra ya está en curso SHALL esperar y reusar el resultado de la que ya está en vuelo, en vez de disparar una segunda pasada redundante.

#### Scenario: El arranque de la app y la vuelta del background se solapan
- **WHEN** la sincronización completa disparada por el trabajo de arranque de la app todavía está en curso y, en ese mismo momento, la app pasa a background y vuelve a primer plano disparando otra sincronización completa
- **THEN** la segunda invocación reusa la sincronización ya en curso en vez de iniciar una pasada adicional en paralelo

---

### Requirement: Orden garantizado al encadenar sincronización completa y fetch de feeds
El sistema SHALL, en cualquier flujo automático que encadene subir el estado local pendiente y disparar un fetch de feeds contra el servidor, subir primero el estado local pendiente (incluyendo borrados de fuentes) y solo después disparar el fetch. El sistema SHALL volver a sincronizar tras el fetch para bajar los cambios que este haya generado.

#### Scenario: El fetch de feeds en segundo plano tras el login respeta el orden
- **WHEN** el sistema dispara el fetch de feeds en segundo plano tras la sincronización inicial de login
- **THEN** cualquier borrado de fuente pendiente de subir ya se subió a la nube antes de que el fetch de feeds se dispare para ese usuario

#### Scenario: Una fuente borrada justo antes del fetch en segundo plano no resucita
- **WHEN** el usuario borra una fuente localmente y, antes de que el fetch de feeds en segundo plano tras el login se dispare, ese borrado ya se subió a la nube como parte del orden garantizado
- **THEN** el fetch de feeds no genera artículos nuevos para esa fuente, y el Inbox no la muestra resucitada tras la sincronización posterior al fetch

---

### Requirement: Push inmediato del borrado de una fuente
El sistema SHALL intentar subir el borrado de una fuente a la nube inmediatamente al eliminarla, sin esperar al próximo trigger de sincronización completa. Este push SHALL ser best-effort: no SHALL bloquear ni retrasar la eliminación local de la fuente ni la actualización de la interfaz, y cualquier falla SHALL ignorarse silenciosamente sin propagarse a la interfaz. El push SHALL intentarse únicamente si hay una sesión de usuario activa.

#### Scenario: Eliminar una fuente con conexión disponible
- **WHEN** el usuario elimina una fuente y el dispositivo tiene conexión
- **THEN** el borrado se sube a la nube sin que el usuario tenga que abrir la app de nuevo, hacer pull-to-refresh, o esperar a que la app pase a background y vuelva

#### Scenario: Eliminar una fuente sin conexión
- **WHEN** el usuario elimina una fuente sin conexión a internet
- **THEN** la eliminación local se completa igual, sin errores visibles para el usuario, y el borrado queda pendiente de subir en la próxima sincronización completa

#### Scenario: Falla el push inmediato pero la sincronización completa lo repara
- **WHEN** el push inmediato del borrado de una fuente falla y luego el dispositivo dispara una sincronización completa
- **THEN** el borrado de esa fuente se sube a la nube en esa sincronización completa

---

### Requirement: Push inmediato del renombrado de una fuente
El sistema SHALL intentar subir el nuevo nombre de una fuente a la nube inmediatamente al renombrarla, sin esperar al próximo trigger de sincronización completa. Este push SHALL ser best-effort: no SHALL bloquear ni retrasar la actualización local del nombre ni la actualización de la interfaz, y cualquier falla SHALL ignorarse silenciosamente sin propagarse a la interfaz. El push SHALL intentarse únicamente si hay una sesión de usuario activa.

#### Scenario: Renombrar una fuente con conexión disponible
- **WHEN** el usuario renombra una fuente y el dispositivo tiene conexión
- **THEN** el nuevo nombre se sube a la nube sin que el usuario tenga que abrir la app de nuevo, hacer pull-to-refresh, o esperar a que la app pase a background y vuelva

#### Scenario: Renombrar una fuente sin conexión
- **WHEN** el usuario renombra una fuente sin conexión a internet
- **THEN** la actualización local del nombre se completa igual, sin errores visibles para el usuario, y el cambio queda pendiente de subir en la próxima sincronización completa

---

### Requirement: Flush de cambios pendientes antes de limpiar datos locales al cerrar sesión
El sistema SHALL intentar una sincronización completa antes de limpiar los datos locales del usuario al cerrar sesión. Si esa sincronización falla, el sistema SHALL informar al usuario, antes de continuar con el cierre de sesión, que puede haber cambios recientes sin sincronizar, dándole la opción de cancelar el cierre de sesión o continuar de todos modos.

#### Scenario: Cerrar sesión con todo ya sincronizado
- **WHEN** el usuario cierra sesión y la sincronización previa al cierre se completa exitosamente
- **THEN** el sistema limpia los datos locales y cierra la sesión sin ningún diálogo adicional

#### Scenario: Cerrar sesión con cambios pendientes que no se pueden subir
- **WHEN** el usuario cierra sesión sin conexión a internet (o con Supabase inalcanzable) y hay cambios locales sin sincronizar
- **THEN** el sistema muestra un aviso indicando que puede haber cambios recientes sin sincronizar, antes de limpiar los datos locales, dando al usuario la opción de cancelar

#### Scenario: El usuario decide cerrar sesión de todos modos
- **WHEN** el usuario ve el aviso de cambios sin sincronizar y elige continuar de todos modos
- **THEN** el sistema limpia los datos locales y cierra la sesión, con la pérdida de esos cambios pendientes como consecuencia conocida de esa decisión

### Requirement: Una fuente activa es única por usuario y feed URL en el servidor
El sistema SHALL garantizar del lado del servidor que un usuario no pueda tener dos fuentes activas (no borradas) con la misma feed URL, sin depender de la verificación que hace el cliente. Las fuentes borradas (`deleted_at` no nulo) SHALL quedar fuera de esta restricción, de modo que volver a agregar un feed que se había eliminado siga siendo posible. La comparación SHALL ser por igualdad exacta de la feed URL.

Al activar esta garantía sobre datos existentes, el sistema SHALL resolver primero cada grupo de fuentes activas duplicadas de un mismo usuario conservando la más antigua (por fecha en que se agregó) y SHALL preservar el trabajo del usuario sobre las demás:
- Los artículos que existan en la fuente conservada con la misma URL que uno de la fuente sobrante SHALL conservar el estado de lectura, favorito y archivado más "avanzado" entre ambos (leído si alguno lo estaba, favorito si alguno lo era, archivado si alguno lo estaba, y la fecha de lectura más temprana entre las no nulas).
- Los artículos que solo existían en la fuente sobrante SHALL pasar a pertenecer a la fuente conservada, con el nombre e ícono de esta.
- Los artículos repetidos de la fuente sobrante SHALL quedar marcados como borrados, y la fuente sobrante SHALL quedar marcada como borrada, de modo que los dispositivos dejen de verlos al sincronizar.

#### Scenario: Un usuario intenta tener dos fuentes activas con el mismo feed
- **WHEN** ya existe una fuente activa de un usuario con una feed URL y se intenta crear otra fuente activa del mismo usuario con esa misma feed URL
- **THEN** el servidor rechaza la segunda con un error de unicidad y no crea la fila

#### Scenario: Dos usuarios distintos pueden tener el mismo feed
- **WHEN** dos usuarios diferentes agregan la misma feed URL
- **THEN** ambos pueden tener su fuente, sin conflicto entre ellos

#### Scenario: Volver a agregar un feed que se había eliminado
- **WHEN** un usuario eliminó una fuente (queda marcada como borrada) y vuelve a agregar la misma feed URL
- **THEN** la nueva fuente se crea sin conflicto con la borrada

#### Scenario: Deduplicación de datos existentes conserva la más antigua
- **WHEN** se activa la garantía y un usuario tiene dos fuentes activas con la misma feed URL
- **THEN** queda activa la que se agregó primero, y la otra queda marcada como borrada

#### Scenario: Deduplicación fusiona el estado de los artículos repetidos
- **WHEN** un artículo está leído en la fuente sobrante y no leído en la conservada con la misma URL
- **THEN** el artículo de la fuente conservada queda leído, y el de la sobrante queda marcado como borrado

#### Scenario: Deduplicación traslada los artículos que solo estaban en la fuente sobrante
- **WHEN** la fuente sobrante tiene un artículo cuya URL no existe en la fuente conservada
- **THEN** ese artículo pasa a la fuente conservada, sin perder su estado de lectura, favorito ni archivado

#### Scenario: Deduplicación no afecta a usuarios sin duplicados
- **WHEN** se activa la garantía y un usuario no tiene fuentes activas con feed URL repetida
- **THEN** sus fuentes y artículos permanecen sin modificar

### Requirement: Un conflicto de unicidad al subir una fuente se reconcilia sin bloquear la sincronización
El sistema SHALL tratar un rechazo de unicidad del servidor al subir una fuente (existe ya una fuente activa del mismo usuario con esa feed URL y un identificador distinto) como un caso que se resuelve, no como un fallo de la sincronización completa. Para ello, SHALL adoptar la fuente remota existente y descartar localmente la fuente duplicada junto con los artículos locales que dependan de ella, y SHALL continuar con la sincronización del resto de las fuentes y del resto de las entidades (artículos, resúmenes, uso de IA y preferencias) en el mismo ciclo.

Al subir fuentes, el sistema SHALL enviar primero las fuentes marcadas como borradas y después las activas, de modo que borrar una fuente y volver a agregar la misma feed URL antes de sincronizar no produzca un conflicto de unicidad contra la fila que se está dando de baja en esa misma subida.

Si el rechazo de unicidad ocurre dentro de una subida por lotes, el sistema SHALL poder identificar cuál fuente lo causó (reintentando fuente por fuente) en lugar de abortar el lote completo, de modo que las fuentes sin conflicto del mismo lote se suban igual. Cualquier otro error de subida SHALL seguir el comportamiento ya definido para los errores de sincronización.

#### Scenario: Un dispositivo agrega un feed que ya existía en la nube sin haberlo sincronizado
- **WHEN** un dispositivo crea localmente una fuente con una feed URL que el mismo usuario ya tiene como fuente activa en la nube, y luego sincroniza
- **THEN** el servidor rechaza esa fila por unicidad, el dispositivo adopta la fuente remota existente, descarta su fuente local duplicada, y el resto de la sincronización se completa sin error

#### Scenario: La fuente duplicada local no deja artículos huérfanos
- **WHEN** el dispositivo descarta su fuente local duplicada tras un conflicto de unicidad
- **THEN** los artículos locales asociados a esa fuente duplicada se eliminan del dispositivo, y los artículos de la fuente remota adoptada se bajan en la misma sincronización

#### Scenario: Un conflicto en una fuente no impide subir las demás del lote
- **WHEN** el lote de fuentes pendientes de subir contiene una fuente que causa un conflicto de unicidad y otras sin conflicto
- **THEN** las fuentes sin conflicto se suben normalmente y solo la conflictiva se reconcilia

#### Scenario: Borrar y volver a agregar el mismo feed antes de sincronizar
- **WHEN** el usuario elimina una fuente y vuelve a agregar la misma feed URL antes de que el borrado se haya sincronizado, y luego sincroniza
- **THEN** la subida envía primero la baja y luego la fuente nueva, sin conflicto de unicidad

#### Scenario: Otro error de subida sigue el comportamiento existente
- **WHEN** la subida de fuentes falla por un motivo distinto de un conflicto de unicidad (sin red, timeout, error del servidor)
- **THEN** el error se clasifica y se maneja como cualquier otro error de sincronización con la nube

### Requirement: Sincronización del estado de descarte de daily_summaries
La tabla remota `daily_summaries` SHALL incluir una columna nullable `dismissed_at` con el instante en que el usuario abrió o descartó el resumen en el Inbox. Al subir cambios locales de `daily_summaries` en la sincronización completa, el sistema SHALL incluir ese valor en la fila enviada. Al bajar cambios remotos, el sistema SHALL reconstruir el `DailySummary` local con ese valor. Si el cambio remoto trae `dismissed_at` vacío pero el `DailySummary` local ya tiene un valor, el sistema SHALL conservar el valor local en vez de reemplazarlo. Un cliente que no envía `dismissed_at` al subir un resumen NO SHALL borrar un valor ya existente en el servidor.

#### Scenario: Subir un resumen descartado
- **WHEN** el sistema sube un `DailySummary` local con `dismissed_at`
- **THEN** la fila enviada incluye ese valor

#### Scenario: Bajar un resumen descartado en otro dispositivo
- **WHEN** el sistema baja un cambio de `daily_summaries` con `dismissed_at` definido
- **THEN** el `DailySummary` local queda con ese `dismissed_at`

#### Scenario: Un remoto sin dismissed_at no pisa el valor local
- **WHEN** el sistema baja un cambio remoto de un resumen con `dismissed_at` vacío y el resumen local ya tiene `dismissed_at`
- **THEN** el `DailySummary` local conserva su `dismissed_at`

#### Scenario: Un cliente anterior no borra el valor del servidor
- **WHEN** un cliente que no conoce `dismissed_at` sube un `DailySummary` hacia una fila que ya tiene `dismissed_at`
- **THEN** el valor de `dismissed_at` en el servidor permanece sin cambios

### Requirement: Push inmediato del descarte de un resumen
El sistema SHALL intentar subir `dismissed_at` (y `updated_at`) de un `DailySummary` a Supabase inmediatamente al descartarlo o abrirlo, sin esperar al próximo trigger de sincronización completa, actualizando solo esas columnas de la fila. Este push SHALL ser best-effort: no SHALL bloquear ni retrasar la actualización local ni la interfaz, y cualquier falla (sin red, error del servidor) SHALL ignorarse sin propagarse a la interfaz. El push SHALL intentarse únicamente si hay una sesión de usuario activa.

#### Scenario: Descartar con conexión disponible
- **WHEN** el usuario descarta o abre el resumen de hoy y el dispositivo tiene conexión
- **THEN** `dismissed_at` se sube a Supabase sin esperar a una sincronización completa

#### Scenario: Descartar sin conexión
- **WHEN** el usuario descarta o abre el resumen sin conexión
- **THEN** la actualización local se completa igual, sin errores visibles, y queda pendiente de subir en la próxima sincronización completa

#### Scenario: Descartar sin sesión activa
- **WHEN** el usuario descarta o abre el resumen sin sesión iniciada
- **THEN** el sistema no intenta ningún push, y la actualización local se completa igual

#### Scenario: El push inmediato no retrasa la interacción
- **WHEN** el usuario descarta la tarjeta
- **THEN** la interfaz refleja el descarte sin esperar la respuesta de red

#### Scenario: Falla el push inmediato pero la sincronización completa lo repara
- **WHEN** el push inmediato falla y luego el dispositivo dispara una sincronización completa
- **THEN** `dismissed_at` se sube en esa sincronización completa
