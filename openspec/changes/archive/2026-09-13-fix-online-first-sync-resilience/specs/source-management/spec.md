## MODIFIED Requirements

### Requirement: Al agregar una fuente exitosamente, navegar a su detalle y sincronizarla
El sistema SHALL, tras agregar una fuente exitosamente, navegar a la pantalla de detalle de esa fuente en vez de permanecer únicamente en la lista de fuentes. Al entrar a esa pantalla como consecuencia directa de haber agregado la fuente, el sistema SHALL primero subir esa fuente a la nube (para que quede disponible antes de disparar el fetch de feeds) y luego disparar automáticamente una sincronización de feeds (ver capability `feed-polling`) antes de mostrar los artículos, mostrando el indicador de carga ya usado para la carga inicial del detalle de una fuente mientras ambos pasos están en curso.

Un error durante cualquiera de esos dos pasos (subir la fuente recién agregada, o el fetch de feeds en sí) SHALL manejarse en silencio: el sistema SHALL mostrar los artículos que hayan quedado disponibles localmente (potencialmente ninguno) sin mostrar ningún mensaje de error, ya que la fuente ya fue validada al momento de agregarla. En particular, un fallo al subir la fuente recién agregada (sin red, error del servidor) NUNCA SHALL dejar la pantalla de detalle mostrando el indicador de carga indefinidamente.

Esta sincronización automática SHALL dispararse únicamente en este flujo (inmediatamente después de agregar la fuente), no cada vez que el usuario entra al detalle de una fuente ya existente por otros medios (ej. desde la lista de fuentes).

#### Scenario: Fuente agregada exitosamente navega a su detalle
- **WHEN** el usuario agrega una fuente y la validación de feed resulta exitosa
- **THEN** el sistema navega a la pantalla de detalle de esa fuente

#### Scenario: El detalle sincroniza automáticamente tras agregar la fuente
- **WHEN** el usuario llega a la pantalla de detalle de una fuente inmediatamente después de agregarla
- **THEN** el sistema muestra un indicador de carga, sube la fuente recién agregada a la nube, dispara la sincronización de feeds, y luego muestra los artículos ya disponibles para esa fuente

#### Scenario: La sincronización automática falla
- **WHEN** la sincronización disparada al entrar al detalle de una fuente recién agregada falla (sin conexión, error de red, o timeout)
- **THEN** el sistema no muestra ningún mensaje de error; muestra los artículos que haya disponibles localmente para esa fuente (potencialmente ninguno)

#### Scenario: Falla específicamente la subida de la fuente recién agregada
- **WHEN** el paso de subir la fuente recién agregada a la nube falla (sin conexión, error del servidor, o timeout) antes de llegar a disparar el fetch de feeds
- **THEN** el sistema sale del indicador de carga y muestra los artículos disponibles localmente para esa fuente (potencialmente ninguno), sin mostrar ningún mensaje de error ni quedarse cargando indefinidamente

#### Scenario: Entrar al detalle de una fuente existente no dispara sincronización automática
- **WHEN** el usuario entra al detalle de una fuente ya existente desde la lista de fuentes (no inmediatamente después de agregarla)
- **THEN** el sistema carga los artículos ya disponibles localmente sin disparar una sincronización automática
