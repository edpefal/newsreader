## MODIFIED Requirements

### Requirement: Fetch on-demand disparado por pull-to-refresh, por login, o al agregar una fuente
El sistema SHALL permitir que el cliente dispare una ejecución del fetch de feeds al hacer pull-to-refresh en el Inbox, automáticamente al completar el login (ver capability `cloud-sync`, requirement "Sincronización automática al iniciar sesión"), o automáticamente al agregar una fuente exitosamente (ver capability `source-management`), antes de sincronizar los cambios locales/remotos en cada caso. No existe un fetch programado en segundo plano (sin cron): el contenido nuevo solo se descubre cuando algún dispositivo de la cuenta hace pull-to-refresh, inicia sesión, o agrega una fuente.

El fetch disparado al agregar una fuente SHALL ser el mismo fetch de cuenta completa que usan pull-to-refresh y login (no un fetch acotado a una sola fuente); el sistema confía en que el servidor prioriza las fuentes nunca sincronizadas para que la recién agregada quede cubierta por esa misma invocación.

Si un pull-to-refresh manual y el fetch automático de login coinciden en el tiempo para el mismo usuario, el sistema SHALL evitar disparar dos invocaciones simultáneas del fetch de feeds: la segunda solicitud SHALL esperar y reutilizar el resultado de la que ya está en curso, en vez de iniciar una invocación adicional. Esta deduplicación no aplica al fetch disparado por agregar una fuente, que es independiente y no comparte invocación en vuelo con el Inbox.

El fetch de feeds del lado del servidor procesa como máximo una cantidad acotada de fuentes por invocación (protección contra agotar el presupuesto de cómputo del servidor). Cuando el pull-to-refresh manual del Inbox se dispara, el sistema SHALL reintentar automáticamente la invocación del fetch de feeds, dentro del mismo gesto, hasta que se hayan intentado sincronizar todas las fuentes del usuario, o hasta alcanzar un tope explícito de reintentos o de tiempo total — lo que ocurra primero. El fetch disparado por login o por agregar una fuente SHALL seguir invocando el fetch de feeds una única vez, sin este mecanismo de reintento.

#### Scenario: Usuario hace pull-to-refresh
- **WHEN** el usuario hace pull-to-refresh en el Inbox
- **THEN** el sistema invoca el fetch de feeds del lado del servidor para las fuentes de ese usuario, y luego sincroniza los artículos resultantes al dispositivo

#### Scenario: Usuario inicia sesión
- **WHEN** el usuario inicia sesión y la sincronización inicial de datos ya existentes en la nube termina
- **THEN** el sistema invoca automáticamente el fetch de feeds del lado del servidor para las fuentes de ese usuario, sin que el usuario tenga que hacer pull-to-refresh

#### Scenario: Usuario agrega una fuente exitosamente
- **WHEN** el usuario agrega una fuente nueva y la validación de feed resulta exitosa
- **THEN** el sistema invoca automáticamente el fetch de feeds del lado del servidor para las fuentes de ese usuario, sin que el usuario tenga que hacer pull-to-refresh ni saber que esa opción existe

#### Scenario: Nadie hace pull-to-refresh, inicia sesión, ni agrega una fuente
- **WHEN** ningún dispositivo de una cuenta hace pull-to-refresh, inicia sesión, ni agrega una fuente durante varias horas
- **THEN** no aparece contenido nuevo hasta que algún dispositivo dispare el fetch por alguno de esos medios — no hay actualización en segundo plano

#### Scenario: Pull-to-refresh manual mientras el fetch de login sigue en curso
- **WHEN** el fetch de feeds disparado automáticamente por el login todavía está en curso, y el usuario hace pull-to-refresh en ese momento
- **THEN** el sistema no dispara una segunda invocación del fetch de feeds; el pull-to-refresh espera el resultado de la invocación ya en curso y continúa su flujo normal (sincronizar estado y recargar) con ese resultado

#### Scenario: Pull-to-refresh con más fuentes que el tope de una invocación
- **WHEN** el usuario tiene más fuentes que las que el servidor procesa en una sola invocación del fetch de feeds, y hace pull-to-refresh
- **THEN** el sistema invoca el fetch de feeds más de una vez dentro del mismo gesto, hasta haber intentado sincronizar todas las fuentes del usuario o alcanzar el tope de reintentos/tiempo, y solo entonces continúa con el resto del flujo de refresh (sincronizar estado y recargar el Inbox)

#### Scenario: Pull-to-refresh con menos fuentes que el tope de una invocación
- **WHEN** el usuario tiene menos fuentes que las que el servidor puede procesar en una sola invocación, y hace pull-to-refresh
- **THEN** el sistema invoca el fetch de feeds una única vez (todas las fuentes del usuario ya quedaron cubiertas), sin reintentos adicionales innecesarios

#### Scenario: El tope de reintentos se alcanza sin cubrir todas las fuentes
- **WHEN** el pull-to-refresh reintenta el fetch de feeds hasta alcanzar el tope de reintentos o de tiempo total, y aun así queda alguna fuente del usuario sin haberse intentado sincronizar en ese gesto
- **THEN** el sistema continúa con el resto del flujo de refresh normalmente (sin bloquear al usuario indefinidamente), y las fuentes restantes quedan pendientes para el próximo pull-to-refresh, igual que el comportamiento existente antes de este cambio

#### Scenario: Una invocación intermedia del reintento falla por error de red
- **WHEN** alguna de las invocaciones del fetch de feeds dentro del loop de reintento de un pull-to-refresh falla por error de red (sin conexión)
- **THEN** el sistema deja de reintentar inmediatamente y reporta el error de red al usuario, en vez de seguir reintentando

#### Scenario: Reporte de fuentes fallidas agregado entre reintentos
- **WHEN** el pull-to-refresh reintentó el fetch de feeds más de una vez dentro del mismo gesto, y una o más fuentes fallaron en alguna de esas invocaciones
- **THEN** el sistema le informa al usuario, al final del gesto de refresh, un conteo de fuentes fallidas sin contar la misma fuente más de una vez, aunque haya fallado en más de una de las invocaciones del reintento
