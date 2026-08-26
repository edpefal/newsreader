## ADDED Requirements

### Requirement: El artículo abierto del Inbox se resalta en la columna central en vez de desaparecer
En el layout de dos paneles, mientras un artículo del Inbox es la selección mostrada en el panel de detalle, el sistema SHALL mantenerlo visible en la columna central con un color de fondo distintivo (adecuado tanto en tema claro como oscuro), en lugar de quitarlo de la lista.

#### Scenario: Usuario toca un artículo no leído del Inbox
- **WHEN** el usuario toca un artículo en la columna central del Inbox en modo de dos paneles
- **THEN** el panel derecho muestra el lector de ese artículo y la fila de ese artículo en la columna central se resalta con un color de fondo distinto, sin desaparecer de la lista

#### Scenario: Artículo resaltado sigue visible tras sincronizar
- **WHEN** el artículo abierto en el panel derecho del Inbox está resaltado en la columna central y ocurre una sincronización (manual o en segundo plano)
- **THEN** el artículo resaltado permanece visible en la columna central mientras siga siendo la selección abierta

### Requirement: El artículo del Inbox solo se archiva de la columna central al cerrarse explícitamente
El sistema SHALL quitar de la columna central del Inbox (animando su salida, igual que hoy) al artículo que estaba resaltado únicamente cuando el usuario lo cierra explícitamente: activando la acción de volver del lector hacia el estado vacío del panel derecho, o seleccionando otro artículo de la columna central.

#### Scenario: Usuario vuelve con el botón de retroceder del lector
- **WHEN** el usuario, con un artículo resaltado y abierto en el panel derecho del Inbox, toca el botón de volver del lector
- **THEN** el panel derecho vuelve al estado vacío y el artículo que estaba resaltado se anima hacia afuera y desaparece de la columna central

#### Scenario: Usuario selecciona otro artículo de la columna central
- **WHEN** el usuario, con un artículo A resaltado y abierto en el panel derecho del Inbox, toca un artículo B distinto en la columna central
- **THEN** el panel derecho pasa a mostrar el lector del artículo B, el artículo A se anima hacia afuera y desaparece de la columna central, y el artículo B pasa a resaltarse

#### Scenario: Cambiar de tab y volver no cierra la selección
- **WHEN** el usuario, con un artículo resaltado y abierto en el panel derecho del Inbox, cambia a otra tab (Favoritos, Archivo, Fuentes o Resúmenes) y luego vuelve al Inbox
- **THEN** el artículo sigue resaltado en la columna central y sigue mostrado en el panel derecho, sin haberse archivado por el cambio de tab
