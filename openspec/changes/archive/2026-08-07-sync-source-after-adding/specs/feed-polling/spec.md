## MODIFIED Requirements

### Requirement: Fetch on-demand disparado por pull-to-refresh, por login, o al agregar una fuente
El sistema SHALL permitir que el cliente dispare una ejecución del fetch de feeds al hacer pull-to-refresh en el Inbox, automáticamente al completar el login (ver capability `cloud-sync`, requirement "Sincronización automática al iniciar sesión"), o automáticamente al agregar una fuente exitosamente (ver capability `source-management`), antes de sincronizar los cambios locales/remotos en cada caso. No existe un fetch programado en segundo plano (sin cron): el contenido nuevo solo se descubre cuando algún dispositivo de la cuenta hace pull-to-refresh, inicia sesión, o agrega una fuente.

El fetch disparado al agregar una fuente SHALL ser el mismo fetch de cuenta completa que usan pull-to-refresh y login (no un fetch acotado a una sola fuente); el sistema confía en que el servidor prioriza las fuentes nunca sincronizadas para que la recién agregada quede cubierta por esa misma invocación.

Si un pull-to-refresh manual y el fetch automático de login coinciden en el tiempo para el mismo usuario, el sistema SHALL evitar disparar dos invocaciones simultáneas del fetch de feeds: la segunda solicitud SHALL esperar y reutilizar el resultado de la que ya está en curso, en vez de iniciar una invocación adicional. Esta deduplicación no aplica al fetch disparado por agregar una fuente, que es independiente y no comparte invocación en vuelo con el Inbox.

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
