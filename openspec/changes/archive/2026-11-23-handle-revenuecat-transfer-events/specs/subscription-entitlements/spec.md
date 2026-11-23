## ADDED Requirements

### Requirement: Traspaso de una suscripción entre cuentas
El sistema SHALL, cuando RevenueCat avise de un traspaso de transacciones y entitlements entre usuarios, sincronizar en `entitlements` el estado vigente de **todos** los usuarios involucrados (los de origen y los de destino), consultando a RevenueCat el estado actual del entitlement `pro` de cada uno, igual que ante cualquier otro evento. El sistema NO SHALL deducir el estado de cada usuario del hecho de ser origen o destino. Un usuario de origen que ya no tiene acceso vigente SHALL quedar con `is_active = false`.

#### Scenario: La cuenta de origen pierde el acceso
- **WHEN** RevenueCat avisa de un traspaso de la cuenta A (origen) a la cuenta B (destino) y el entitlement `pro` de A ya no está vigente
- **THEN** el sistema marca `is_active = false` para A en `entitlements`

#### Scenario: La cuenta de destino recibe el acceso
- **WHEN** RevenueCat avisa de un traspaso de la cuenta A a la cuenta B y el entitlement `pro` de B está vigente
- **THEN** el sistema marca `is_active = true` para B en `entitlements`

#### Scenario: Origen y destino se sincronizan con un solo aviso
- **WHEN** llega un único aviso de traspaso con un usuario de origen y uno de destino
- **THEN** el sistema actualiza `entitlements` de ambos con el estado vigente que informa RevenueCat para cada uno

#### Scenario: Identificadores anónimos o inexistentes dentro del traspaso se ignoran
- **WHEN** un aviso de traspaso incluye un identificador anónimo de RevenueCat, o un `user_id` que no existe en `auth.users` del proyecto que recibe el webhook
- **THEN** el sistema omite ese identificador sin crear ni modificar su fila, y sincroniza normalmente a los demás usuarios del aviso

#### Scenario: Falla la sincronización de alguno de los usuarios
- **WHEN** la consulta a RevenueCat o la escritura en `entitlements` falla para alguno de los usuarios de un aviso de traspaso
- **THEN** el sistema responde con un error de servidor para que RevenueCat reintente, sin dejar de intentar sincronizar a los demás usuarios del aviso

#### Scenario: El reintento de un traspaso es seguro
- **WHEN** RevenueCat reenvía un aviso de traspaso que ya se había procesado total o parcialmente
- **THEN** `entitlements` queda con el estado vigente de cada usuario, sin duplicar filas ni retroceder a un estado anterior

#### Scenario: Aviso sin usuario identificable que no es un traspaso
- **WHEN** llega un aviso sin `app_user_id` que no es un traspaso ni trae listas de usuarios
- **THEN** el sistema responde 200 sin consultar a RevenueCat ni modificar `entitlements`

#### Scenario: Traspaso sin la autorización correcta
- **WHEN** llega un aviso de traspaso cuya cabecera de autorización no coincide con el valor configurado
- **THEN** el sistema responde 401 sin consultar a RevenueCat ni modificar `entitlements`
