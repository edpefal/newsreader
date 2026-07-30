## ADDED Requirements

### Requirement: Indicador de progreso visible durante la sincronización al volver del background
El sistema SHALL mostrar un indicador de progreso no bloqueante (`LinearProgressIndicator` debajo del `AppBar` del Inbox) mientras la sincronización disparada al volver del background está en curso, sin ocultar ni reemplazar los artículos ya cargados en pantalla. El indicador SHALL desaparecer automáticamente al terminar la sincronización, tanto si finaliza con éxito como con error.

#### Scenario: Volver del background con el Inbox ya cargado
- **WHEN** el usuario tiene el Inbox con artículos visibles, manda la app a segundo plano, y vuelve a traerla a primer plano
- **THEN** aparece un `LinearProgressIndicator` debajo del título mientras la sincronización está en curso, y los artículos ya cargados siguen visibles sin interrupción

#### Scenario: La sincronización termina
- **WHEN** la sincronización disparada por el resume termina (con o sin artículos nuevos)
- **THEN** el indicador de progreso desaparece y, si hubo cambios, el Inbox se actualiza con el contenido nuevo
