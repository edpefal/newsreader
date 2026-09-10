## ADDED Requirements

### Requirement: La agrupación por fuente sobrevive un ciclo de sincronización
La agrupación por fuente (`sourceBlocks`, con identificador y nombre de cada fuente y los ids de sus artículos) que el sistema persiste junto a un `DailySummary` recién generado SHALL seguir presente en el registro local después de que ese resumen participe en un ciclo de sincronización con la nube (subida y bajada), sin importar cuán pronto ocurra ese ciclo después de la generación.

#### Scenario: sourceBlocks sobrevive a una sincronización inmediatamente después de generar
- **WHEN** el sistema genera exitosamente un `DailySummary` con su agrupación por fuente, y a continuación corre un ciclo de sincronización (por ejemplo al abrir o refrescar el inbox)
- **THEN** el registro local de ese `DailySummary` conserva la misma agrupación por fuente (mismos ids de fuente, nombres, e ids de artículos) que tenía antes de sincronizar

#### Scenario: Un resumen bajado de la nube sin agrupación por fuente no borra la agrupación local existente
- **WHEN** el sistema baja de la nube un registro de `daily_summaries` que no trae agrupación por fuente para un resumen que localmente ya tiene una
- **THEN** el sistema SHALL preservar la agrupación por fuente local en vez de sobrescribirla con un valor vacío
