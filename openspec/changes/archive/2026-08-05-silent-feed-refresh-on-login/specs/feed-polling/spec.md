## MODIFIED Requirements

### Requirement: Fetch on-demand disparado por pull-to-refresh o por login
El sistema SHALL permitir que el cliente dispare una ejecución del fetch de feeds al hacer pull-to-refresh en el Inbox, o automáticamente al completar el login (ver capability `cloud-sync`, requirement "Sincronización automática al iniciar sesión"), antes de sincronizar los cambios locales/remotos en cada caso. No existe un fetch programado en segundo plano (sin cron): el contenido nuevo solo se descubre cuando algún dispositivo de la cuenta hace pull-to-refresh o inicia sesión.

Si un pull-to-refresh manual y el fetch automático de login coinciden en el tiempo para el mismo usuario, el sistema SHALL evitar disparar dos invocaciones simultáneas del fetch de feeds: la segunda solicitud SHALL esperar y reutilizar el resultado de la que ya está en curso, en vez de iniciar una invocación adicional.

#### Scenario: Usuario hace pull-to-refresh
- **WHEN** el usuario hace pull-to-refresh en el Inbox
- **THEN** el sistema invoca el fetch de feeds del lado del servidor para las fuentes de ese usuario, y luego sincroniza los artículos resultantes al dispositivo

#### Scenario: Usuario inicia sesión
- **WHEN** el usuario inicia sesión y la sincronización inicial de datos ya existentes en la nube termina
- **THEN** el sistema invoca automáticamente el fetch de feeds del lado del servidor para las fuentes de ese usuario, sin que el usuario tenga que hacer pull-to-refresh

#### Scenario: Nadie hace pull-to-refresh ni inicia sesión
- **WHEN** ningún dispositivo de una cuenta hace pull-to-refresh ni inicia sesión durante varias horas
- **THEN** no aparece contenido nuevo hasta que algún dispositivo dispare el fetch manualmente o vía login — no hay actualización en segundo plano

#### Scenario: Pull-to-refresh manual mientras el fetch de login sigue en curso
- **WHEN** el fetch de feeds disparado automáticamente por el login todavía está en curso, y el usuario hace pull-to-refresh en ese momento
- **THEN** el sistema no dispara una segunda invocación del fetch de feeds; el pull-to-refresh espera el resultado de la invocación ya en curso y continúa su flujo normal (sincronizar estado y recargar) con ese resultado
