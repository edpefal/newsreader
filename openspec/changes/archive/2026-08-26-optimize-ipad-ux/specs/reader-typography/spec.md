## ADDED Requirements

### Requirement: Ancho máximo del cuerpo del artículo
El lector SHALL limitar el ancho del texto del cuerpo del artículo (contenido HTML) a un máximo fijo de aproximadamente 680pt, centrado horizontalmente dentro del espacio disponible, independientemente de si ese espacio es la pantalla completa o el panel derecho de un layout de dos paneles.

#### Scenario: Panel o pantalla más ancha que el máximo
- **WHEN** el ancho disponible para el lector supera los ~680pt
- **THEN** el texto del cuerpo del artículo se muestra con un ancho de ~680pt centrado, dejando márgenes simétricos a los costados

#### Scenario: Panel o pantalla más angosta que el máximo
- **WHEN** el ancho disponible para el lector es menor a ~680pt (por ejemplo, un iPhone en portrait)
- **THEN** el texto del cuerpo del artículo ocupa todo el ancho disponible, igual que el comportamiento actual

#### Scenario: iPhone en landscape
- **WHEN** el usuario abre un artículo en un iPhone en orientación landscape con un ancho disponible mayor a ~680pt
- **THEN** el texto del cuerpo del artículo se limita a ~680pt centrado, en lugar de estirarse al ancho completo de la pantalla
