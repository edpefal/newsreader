## ADDED Requirements

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
