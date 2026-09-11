## ADDED Requirements

### Requirement: Sincronización de daily_summaries incluye la agrupación por fuente
La tabla remota `daily_summaries` SHALL incluir una columna para la agrupación por fuente del resumen (identificador y nombre de cada fuente, e ids de sus artículos de ese día). Al subir cambios locales de `daily_summaries`, el sistema SHALL incluir esta agrupación en la fila enviada. Al bajar cambios remotos, el sistema SHALL reconstruir esta agrupación a partir de esa columna.

#### Scenario: Subir un resumen incluye su agrupación por fuente
- **WHEN** el sistema sube un `DailySummary` local que tiene agrupación por fuente hacia `daily_summaries`
- **THEN** la fila enviada incluye esa agrupación por fuente completa

#### Scenario: Bajar un resumen reconstruye su agrupación por fuente
- **WHEN** el sistema baja un cambio de `daily_summaries` que incluye la columna de agrupación por fuente
- **THEN** el sistema reconstruye el `DailySummary` local con esa misma agrupación por fuente
