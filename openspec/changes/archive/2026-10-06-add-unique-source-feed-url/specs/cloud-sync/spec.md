## ADDED Requirements

### Requirement: Una fuente activa es única por usuario y feed URL en el servidor
El sistema SHALL garantizar del lado del servidor que un usuario no pueda tener dos fuentes activas (no borradas) con la misma feed URL, sin depender de la verificación que hace el cliente. Las fuentes borradas (`deleted_at` no nulo) SHALL quedar fuera de esta restricción, de modo que volver a agregar un feed que se había eliminado siga siendo posible. La comparación SHALL ser por igualdad exacta de la feed URL.

Al activar esta garantía sobre datos existentes, el sistema SHALL resolver primero cada grupo de fuentes activas duplicadas de un mismo usuario conservando la más antigua (por fecha en que se agregó) y SHALL preservar el trabajo del usuario sobre las demás:
- Los artículos que existan en la fuente conservada con la misma URL que uno de la fuente sobrante SHALL conservar el estado de lectura, favorito y archivado más "avanzado" entre ambos (leído si alguno lo estaba, favorito si alguno lo era, archivado si alguno lo estaba, y la fecha de lectura más temprana entre las no nulas).
- Los artículos que solo existían en la fuente sobrante SHALL pasar a pertenecer a la fuente conservada, con el nombre e ícono de esta.
- Los artículos repetidos de la fuente sobrante SHALL quedar marcados como borrados, y la fuente sobrante SHALL quedar marcada como borrada, de modo que los dispositivos dejen de verlos al sincronizar.

#### Scenario: Un usuario intenta tener dos fuentes activas con el mismo feed
- **WHEN** ya existe una fuente activa de un usuario con una feed URL y se intenta crear otra fuente activa del mismo usuario con esa misma feed URL
- **THEN** el servidor rechaza la segunda con un error de unicidad y no crea la fila

#### Scenario: Dos usuarios distintos pueden tener el mismo feed
- **WHEN** dos usuarios diferentes agregan la misma feed URL
- **THEN** ambos pueden tener su fuente, sin conflicto entre ellos

#### Scenario: Volver a agregar un feed que se había eliminado
- **WHEN** un usuario eliminó una fuente (queda marcada como borrada) y vuelve a agregar la misma feed URL
- **THEN** la nueva fuente se crea sin conflicto con la borrada

#### Scenario: Deduplicación de datos existentes conserva la más antigua
- **WHEN** se activa la garantía y un usuario tiene dos fuentes activas con la misma feed URL
- **THEN** queda activa la que se agregó primero, y la otra queda marcada como borrada

#### Scenario: Deduplicación fusiona el estado de los artículos repetidos
- **WHEN** un artículo está leído en la fuente sobrante y no leído en la conservada con la misma URL
- **THEN** el artículo de la fuente conservada queda leído, y el de la sobrante queda marcado como borrado

#### Scenario: Deduplicación traslada los artículos que solo estaban en la fuente sobrante
- **WHEN** la fuente sobrante tiene un artículo cuya URL no existe en la fuente conservada
- **THEN** ese artículo pasa a la fuente conservada, sin perder su estado de lectura, favorito ni archivado

#### Scenario: Deduplicación no afecta a usuarios sin duplicados
- **WHEN** se activa la garantía y un usuario no tiene fuentes activas con feed URL repetida
- **THEN** sus fuentes y artículos permanecen sin modificar

### Requirement: Un conflicto de unicidad al subir una fuente se reconcilia sin bloquear la sincronización
El sistema SHALL tratar un rechazo de unicidad del servidor al subir una fuente (existe ya una fuente activa del mismo usuario con esa feed URL y un identificador distinto) como un caso que se resuelve, no como un fallo de la sincronización completa. Para ello, SHALL adoptar la fuente remota existente y descartar localmente la fuente duplicada junto con los artículos locales que dependan de ella, y SHALL continuar con la sincronización del resto de las fuentes y del resto de las entidades (artículos, resúmenes, uso de IA y preferencias) en el mismo ciclo.

Al subir fuentes, el sistema SHALL enviar primero las fuentes marcadas como borradas y después las activas, de modo que borrar una fuente y volver a agregar la misma feed URL antes de sincronizar no produzca un conflicto de unicidad contra la fila que se está dando de baja en esa misma subida.

Si el rechazo de unicidad ocurre dentro de una subida por lotes, el sistema SHALL poder identificar cuál fuente lo causó (reintentando fuente por fuente) en lugar de abortar el lote completo, de modo que las fuentes sin conflicto del mismo lote se suban igual. Cualquier otro error de subida SHALL seguir el comportamiento ya definido para los errores de sincronización.

#### Scenario: Un dispositivo agrega un feed que ya existía en la nube sin haberlo sincronizado
- **WHEN** un dispositivo crea localmente una fuente con una feed URL que el mismo usuario ya tiene como fuente activa en la nube, y luego sincroniza
- **THEN** el servidor rechaza esa fila por unicidad, el dispositivo adopta la fuente remota existente, descarta su fuente local duplicada, y el resto de la sincronización se completa sin error

#### Scenario: La fuente duplicada local no deja artículos huérfanos
- **WHEN** el dispositivo descarta su fuente local duplicada tras un conflicto de unicidad
- **THEN** los artículos locales asociados a esa fuente duplicada se eliminan del dispositivo, y los artículos de la fuente remota adoptada se bajan en la misma sincronización

#### Scenario: Un conflicto en una fuente no impide subir las demás del lote
- **WHEN** el lote de fuentes pendientes de subir contiene una fuente que causa un conflicto de unicidad y otras sin conflicto
- **THEN** las fuentes sin conflicto se suben normalmente y solo la conflictiva se reconcilia

#### Scenario: Borrar y volver a agregar el mismo feed antes de sincronizar
- **WHEN** el usuario elimina una fuente y vuelve a agregar la misma feed URL antes de que el borrado se haya sincronizado, y luego sincroniza
- **THEN** la subida envía primero la baja y luego la fuente nueva, sin conflicto de unicidad

#### Scenario: Otro error de subida sigue el comportamiento existente
- **WHEN** la subida de fuentes falla por un motivo distinto de un conflicto de unicidad (sin red, timeout, error del servidor)
- **THEN** el error se clasifica y se maneja como cualquier otro error de sincronización con la nube
