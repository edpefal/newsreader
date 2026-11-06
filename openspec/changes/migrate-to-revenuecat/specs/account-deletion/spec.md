## ADDED Requirements

### Requirement: Aviso sobre la suscripción activa al eliminar la cuenta
El sistema SHALL, cuando el usuario con una suscripción activa inicia la eliminación de su cuenta, indicar en la confirmación que eliminar la cuenta no cancela la suscripción de Apple y que debe cancelarla desde los ajustes de su Apple ID para no seguir siendo cobrado, ofreciendo una acción que abra la página de gestión de suscripciones de Apple. El aviso NO SHALL mostrarse a usuarios sin suscripción activa y NO SHALL impedir ni condicionar el borrado.

#### Scenario: Usuario suscrito inicia el borrado
- **WHEN** un usuario con suscripción activa toca "Eliminar cuenta"
- **THEN** la confirmación incluye el aviso de que la suscripción no se cancela y una acción para gestionarla

#### Scenario: Usuario sin suscripción no ve el aviso
- **WHEN** un usuario sin suscripción activa toca "Eliminar cuenta"
- **THEN** la confirmación no menciona ninguna suscripción

#### Scenario: El aviso no bloquea el borrado
- **WHEN** un usuario suscrito ve el aviso y confirma la eliminación sin gestionar la suscripción
- **THEN** el sistema procede con el borrado de la cuenta

### Requirement: Borrado del cliente en RevenueCat
El sistema SHALL, al eliminar una cuenta, solicitar a RevenueCat el borrado del cliente asociado al `user_id` de esa cuenta. Si esa solicitud falla, el sistema SHALL registrar el error en la observabilidad sin incluir PII y NO SHALL impedir ni revertir el borrado de la cuenta.

#### Scenario: Cuenta eliminada sin dejar el cliente en RevenueCat
- **WHEN** se completa el borrado de una cuenta
- **THEN** el cliente de ese `user_id` es eliminado de RevenueCat

#### Scenario: Falla el borrado en RevenueCat
- **WHEN** la solicitud de borrado a RevenueCat falla durante la eliminación de una cuenta
- **THEN** el error queda registrado, y la cuenta y sus datos se eliminan igualmente
