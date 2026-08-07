## ADDED Requirements

### Requirement: Al agregar una fuente exitosamente, navegar a su detalle y sincronizarla
El sistema SHALL, tras agregar una fuente exitosamente, navegar a la pantalla de detalle de esa fuente en vez de permanecer únicamente en la lista de fuentes. Al entrar a esa pantalla como consecuencia directa de haber agregado la fuente, el sistema SHALL disparar automáticamente una sincronización de feeds (ver capability `feed-polling`) antes de mostrar los artículos, mostrando el indicador de carga ya usado para la carga inicial del detalle de una fuente mientras la sincronización está en curso.

Un error durante esa sincronización SHALL manejarse en silencio: el sistema SHALL mostrar los artículos que hayan quedado disponibles localmente (potencialmente ninguno) sin mostrar ningún mensaje de error, ya que la fuente ya fue validada al momento de agregarla.

Esta sincronización automática SHALL dispararse únicamente en este flujo (inmediatamente después de agregar la fuente), no cada vez que el usuario entra al detalle de una fuente ya existente por otros medios (ej. desde la lista de fuentes).

#### Scenario: Fuente agregada exitosamente navega a su detalle
- **WHEN** el usuario agrega una fuente y la validación de feed resulta exitosa
- **THEN** el sistema navega a la pantalla de detalle de esa fuente

#### Scenario: El detalle sincroniza automáticamente tras agregar la fuente
- **WHEN** el usuario llega a la pantalla de detalle de una fuente inmediatamente después de agregarla
- **THEN** el sistema muestra un indicador de carga, dispara la sincronización de feeds, y luego muestra los artículos ya disponibles para esa fuente

#### Scenario: La sincronización automática falla
- **WHEN** la sincronización disparada al entrar al detalle de una fuente recién agregada falla (sin conexión, error de red, o timeout)
- **THEN** el sistema no muestra ningún mensaje de error; muestra los artículos que haya disponibles localmente para esa fuente (potencialmente ninguno)

#### Scenario: Entrar al detalle de una fuente existente no dispara sincronización automática
- **WHEN** el usuario entra al detalle de una fuente ya existente desde la lista de fuentes (no inmediatamente después de agregarla)
- **THEN** el sistema carga los artículos ya disponibles localmente sin disparar una sincronización automática

---

## MODIFIED Requirements

### Requirement: La lista de fuentes se actualiza al navegar al tab de Fuentes
El sistema SHALL recargar la lista de fuentes cada vez que el usuario toca el tab "Fuentes" en la barra de navegación inferior, de forma consistente con el comportamiento de los tabs Favoritos y Leídos. Al volver de agregar una fuente exitosamente, el sistema SHALL recargar la lista de fuentes independientemente de que la navegación continúe hacia el detalle de la fuente recién agregada (ver requirement "Al agregar una fuente exitosamente, navegar a su detalle y sincronizarla").

#### Scenario: Usuario toca el tab Fuentes después de importar OPML
- **WHEN** el usuario importa fuentes vía OPML y luego toca el tab "Fuentes"
- **THEN** la lista muestra las fuentes recién importadas sin necesidad de reiniciar la app ni hacer pull-to-refresh

#### Scenario: Usuario agrega una fuente manualmente
- **WHEN** el usuario agrega una fuente manualmente vía URL exitosamente
- **THEN** la lista de fuentes queda actualizada con la fuente recién agregada, aunque la navegación inmediata sea hacia el detalle de esa fuente y no hacia la lista

#### Scenario: Usuario toca el tab Fuentes ya estando en él
- **WHEN** el usuario toca el tab "Fuentes" mientras ya está visible la pantalla de fuentes
- **THEN** la lista se recarga (scroll al inicio si corresponde, sin efecto visual molesto)
