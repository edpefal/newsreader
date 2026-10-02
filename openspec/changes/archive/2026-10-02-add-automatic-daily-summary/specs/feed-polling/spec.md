## ADDED Requirements

### Requirement: Fetch periódico en background, en lotes acotados sin depender de un usuario en particular
El sistema SHALL ejecutar periódicamente, en background y sin que ningún cliente lo dispare, una invocación del fetch de feeds acotada a una cantidad fija de fuentes — las globalmente menos recientemente sincronizadas entre todos los usuarios, no las de un usuario en particular. Esta invocación en background SHALL usar el mismo mecanismo de fetch, dedupe y aislamiento de fallos por fuente que el fetch on-demand, y SHALL respetar el mismo tope de fuentes por invocación que existe para proteger el presupuesto de cómputo del servidor.

#### Scenario: Corrida periódica de background
- **WHEN** transcurre el intervalo configurado desde la última corrida del fetch en background
- **THEN** el sistema invoca el fetch de feeds para el lote de fuentes globalmente menos recientemente sincronizadas, sin que ningún usuario haya disparado la acción

#### Scenario: El fetch en background no interfiere con el fetch on-demand
- **WHEN** un usuario hace pull-to-refresh, inicia sesión, o agrega una fuente mientras una corrida en background está en curso
- **THEN** ambos fetches se ejecutan de forma independiente, cada uno respetando su propio tope de fuentes por invocación, sin que uno bloquee o cancele al otro

#### Scenario: Con el tiempo, todas las fuentes de la base terminan frescas
- **WHEN** el fetch en background corre repetidamente durante un período prolongado, sin que ningún usuario haga pull-to-refresh
- **THEN** las fuentes de todos los usuarios eventualmente quedan sincronizadas, en el orden de las menos recientemente sincronizadas primero, sin que ninguna corrida individual exceda el tope de fuentes por invocación
