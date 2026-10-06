## MODIFIED Requirements

### Requirement: Detalle de un resumen
El sistema SHALL permitir ver el texto completo de un `DailySummary` al seleccionar su item en la lista. El texto SHALL presentarse dividido por fuente: el nombre de cada fuente (primera línea de cada bloque separado por línea en blanco) SHALL mostrarse en negrita, seguido del párrafo correspondiente.

Si la primera línea de un bloque lleva como prefijo una etiqueta de fuente (`Fuente:` en español, `Source:` en inglés o `Source :` en francés, sin distinguir mayúsculas de minúsculas, con o sin espacios alrededor de los dos puntos), el sistema SHALL ignorar esa etiqueta tanto al mostrar el nombre de la fuente en negrita como al emparejar el bloque con la agrupación por fuente persistida: el nombre mostrado y el usado para el emparejamiento SHALL ser el que queda después de quitar la etiqueta y los espacios sobrantes. Este requisito aplica a cualquier `DailySummary`, incluidos los ya guardados antes de este cambio.

Debajo de cada párrafo, cuando el `DailySummary` tiene agrupación por fuente persistida y el nombre de esa fuente coincide con el bloque parseado, el sistema SHALL ofrecer navegación a los artículos que generaron ese párrafo:
- Si la fuente aportó un único artículo ese día, SHALL mostrarse un link directo a su detalle.
- Si aportó más de uno, SHALL mostrarse un link por artículo (título truncado).
- Los artículos referenciados que ya no existan localmente (ej. su fuente fue eliminada después) SHALL omitirse sin afectar al resto de los links de ese bloque.

Cuando el `DailySummary` no tiene agrupación por fuente persistida (resúmenes generados antes de esta funcionalidad), o el nombre de un bloque no coincide con ninguna fuente de la agrupación persistida, el sistema SHALL mostrar igualmente el título en negrita, sin ningún link debajo de ese bloque.

#### Scenario: Ver detalle de un resumen
- **WHEN** el usuario toca un item de la lista de resúmenes
- **THEN** el sistema navega a una pantalla de detalle que muestra el texto completo, la fecha y la cantidad de artículos de ese resumen

#### Scenario: Título de cada bloque en negrita
- **WHEN** se muestra el detalle de un `DailySummary`
- **THEN** el nombre de cada fuente (primera línea de cada bloque separado por línea en blanco) se muestra con estilo en negrita, distinguible del resto del párrafo

#### Scenario: Un artículo por fuente muestra un link directo
- **WHEN** la agrupación persistida indica que una fuente aportó un único artículo ese día
- **THEN** debajo del párrafo de esa fuente se muestra un link que navega directo al detalle de ese artículo

#### Scenario: Varios artículos por fuente muestran una fila de links
- **WHEN** la agrupación persistida indica que una fuente aportó más de un artículo ese día
- **THEN** debajo del párrafo de esa fuente se muestra un link por artículo, cada uno con el título truncado, cada uno navegando al detalle del artículo correspondiente

#### Scenario: Resumen sin agrupación persistida no muestra links
- **WHEN** el `DailySummary` fue generado antes de esta funcionalidad (sin agrupación por fuente persistida)
- **THEN** el sistema muestra los títulos de fuente en negrita igual que cualquier otro resumen, sin ningún link debajo de los párrafos

#### Scenario: Artículo referenciado ya no existe localmente
- **WHEN** uno de los `articleIds` de la agrupación persistida ya no corresponde a ningún artículo local (fue eliminado en cascada al borrar su fuente)
- **THEN** el sistema omite el link de ese artículo puntual sin afectar los demás links del mismo bloque ni el resto de la pantalla

#### Scenario: Bloque con etiqueta "Fuente:" se empareja y muestra sin la etiqueta
- **WHEN** el texto de un `DailySummary` ya guardado empieza un bloque con `Fuente: TechCrunch` y la agrupación persistida tiene una fuente llamada `TechCrunch` con 2 artículos
- **THEN** el sistema muestra `TechCrunch` en negrita (sin la etiqueta) y debajo del párrafo muestra un link por cada uno de esos 2 artículos

#### Scenario: Etiqueta en otro idioma o con espacio antes de los dos puntos
- **WHEN** el primer renglón de un bloque es `Source: Stratechery` o `Source : Stratechery`, o `fuente: Stratechery` en minúsculas
- **THEN** el sistema se comporta igual que en el escenario anterior: ignora la etiqueta y empareja por el nombre `Stratechery`

#### Scenario: Una fuente cuyo nombre contiene dos puntos no se altera
- **WHEN** el primer renglón de un bloque es `Reuters: World News` y esa es exactamente la fuente persistida (no empieza con `Fuente`/`Source`)
- **THEN** el sistema NO quita nada de ese renglón, lo muestra completo y lo empareja por el nombre completo

## ADDED Requirements

### Requirement: El encabezado de cada fuente en el texto generado es solo el nombre de la fuente
El sistema SHALL persistir en `DailySummary.content` cada bloque de fuente con su primera línea igual al nombre de la fuente, sin ninguna etiqueta delante (`Fuente:`, `Source:`, etc.), incluso si la API de IA devolvió esa etiqueta en su respuesta: el servidor SHALL quitarla de la primera línea de cada bloque antes de guardar el resumen. La quita SHALL aplicarse únicamente cuando, una vez quitada la etiqueta, el resto de la línea coincide con el nombre de una de las fuentes de la agrupación por fuente de ese resumen, y nunca a texto dentro del párrafo, y SHALL dejar el resto del contenido sin cambios. La solicitud enviada a la API de IA (qué artículos y qué contenido se envían, y cómo se rotulan) SHALL permanecer sin cambios.

#### Scenario: La API de IA devuelve el encabezado con etiqueta
- **WHEN** la API de IA responde con un bloque cuya primera línea es `Fuente: TechCrunch`
- **THEN** el `DailySummary` se guarda con esa primera línea como `TechCrunch`, y el párrafo del bloque queda intacto

#### Scenario: La API de IA devuelve el encabezado sin etiqueta
- **WHEN** la API de IA responde con un bloque cuya primera línea es `TechCrunch`
- **THEN** el `DailySummary` se guarda exactamente como llegó, sin ninguna modificación

#### Scenario: La palabra "Fuente" dentro del párrafo no se toca
- **WHEN** el párrafo de un bloque contiene la frase `Fuente: según el reporte` en una línea que no es la primera del bloque
- **THEN** el sistema conserva esa línea tal cual en el `DailySummary` guardado

#### Scenario: Una primera línea con dos puntos que no es una etiqueta de fuente no se altera
- **WHEN** la API de IA responde con un bloque cuya primera línea es `Fuente: desconocida`, y `desconocida` no es el nombre de ninguna fuente de la agrupación de ese resumen
- **THEN** el sistema guarda esa línea sin modificarla

#### Scenario: El texto limpio sigue emparejando con la agrupación persistida
- **WHEN** se genera un resumen nuevo y la API de IA copió la etiqueta en alguno de los bloques
- **THEN** la primera línea de cada bloque guardado coincide exactamente con el `sourceName` de su entrada en la agrupación por fuente persistida
