## ADDED Requirements

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
