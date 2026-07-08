## ADDED Requirements

### Requirement: Los feeds del OPML aparecen progresivamente mientras se validan
El sistema SHALL mostrar cada feed en la lista de preview tan pronto como su validación individual termine, sin esperar a que todos los feeds hayan completado.

#### Scenario: Feed válido aparece mientras otros aún validan
- **WHEN** un feed termina su validación exitosamente mientras otros feeds aún están pendientes
- **THEN** ese feed aparece inmediatamente en la lista con estado "válido y seleccionado", y se ve un indicador de cuántos feeds quedan por validar

#### Scenario: Feed con error aparece mientras otros aún validan
- **WHEN** un feed falla su validación mientras otros aún están pendientes
- **THEN** ese feed aparece en la lista con estado "error", sin bloquear la aparición de los feeds que sigan validando

#### Scenario: Feed duplicado aparece sin red mientras otros aún validan
- **WHEN** un feed ya existe en las fuentes del usuario (detectado sin red)
- **THEN** aparece inmediatamente como "Ya suscrito" sin esperar validaciones de red

#### Scenario: Todos los feeds terminan de validar
- **WHEN** el último feed pendiente completa su validación
- **THEN** desaparece el indicador de carga pendiente y el botón "Importar (N)" queda habilitado si hay al menos un feed seleccionado

#### Scenario: La lista es interactiva desde el primer resultado
- **WHEN** al menos un feed ha aparecido en la lista aunque haya feeds aún validando
- **THEN** el usuario puede hacer scroll, desmarcar checkboxes y ver los resultados ya disponibles
