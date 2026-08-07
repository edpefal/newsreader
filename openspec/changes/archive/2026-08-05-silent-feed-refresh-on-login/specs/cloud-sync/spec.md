## MODIFIED Requirements

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
