## RENAMED Requirements

- FROM: `### Requirement: Listado de resúmenes diarios`
- TO: `### Requirement: Resumen más reciente en la tab Resúmenes`

## MODIFIED Requirements

### Requirement: Resumen más reciente en la tab Resúmenes
El sistema SHALL mostrar en la tab Resúmenes únicamente el `DailySummary` de fecha más reciente, directamente en la raíz de la tab y sin una lista previa, con el detalle descrito en el Requirement "Detalle de un resumen". Los `DailySummary` anteriores NO SHALL ser accesibles desde ninguna pantalla ni ruta de la app; SHALL permanecer almacenados y sincronizados sin cambios.

Cuando no existe ningún `DailySummary` (por ejemplo, un usuario nuevo), la tab SHALL mostrar un estado vacío con un texto que indique que todavía no hay resúmenes y que se creará uno más adelante. Todo texto nuevo SHALL estar disponible en inglés, español y francés.

#### Scenario: Sin resúmenes, estado vacío
- **WHEN** el usuario entra a la tab Resúmenes y no existe ningún `DailySummary`
- **THEN** el sistema muestra un estado vacío que indica que aún no hay resúmenes y que se creará uno más adelante, sin lista ni items

#### Scenario: Un solo resumen
- **WHEN** existe exactamente un `DailySummary`
- **THEN** el sistema muestra directamente ese resumen en la tab

#### Scenario: Varios resúmenes, solo el más reciente
- **WHEN** existen varios `DailySummary` de fechas distintas
- **THEN** la tab muestra solo el de fecha más reciente, y ninguno de los anteriores es accesible desde la UI

#### Scenario: Un resumen anterior no es accesible por ruta
- **WHEN** el usuario intenta abrir la ruta `/summaries/{fecha}` de un `DailySummary` que no es el más reciente
- **THEN** el sistema no muestra ese resumen


### Requirement: Detalle de un resumen
El sistema SHALL mostrar el texto completo de un `DailySummary` en dos lugares: como contenido de la tab Resúmenes (el resumen más reciente, ver Requirement "Resumen más reciente en la tab Resúmenes") y, para el resumen de hoy, al abrirlo desde la tarjeta del Inbox. El texto SHALL presentarse dividido por fuente: el nombre de cada fuente (primera línea de cada bloque separado por línea en blanco) SHALL mostrarse en negrita, seguido del párrafo correspondiente.

Si la primera línea de un bloque lleva como prefijo una etiqueta de fuente (`Fuente:` en español, `Source:` en inglés o `Source :` en francés, sin distinguir mayúsculas de minúsculas, con o sin espacios alrededor de los dos puntos), el sistema SHALL ignorar esa etiqueta tanto al mostrar el nombre de la fuente en negrita como al emparejar el bloque con la agrupación por fuente persistida: el nombre mostrado y el usado para el emparejamiento SHALL ser el que queda después de quitar la etiqueta y los espacios sobrantes. Este requisito aplica a cualquier `DailySummary`, incluidos los ya guardados antes de este cambio.

Cuando el `DailySummary` tiene agrupación por fuente persistida y el nombre de un bloque coincide con una fuente de esa agrupación, el sistema SHALL presentar ese bloque como una **tarjeta** con:
- un encabezado que muestra el ícono de la fuente (`SourceIcon`, con el `iconUrl` de la fuente local correspondiente al `sourceId`) a la izquierda de su nombre en negrita, y a la derecha, en texto discreto, la cantidad de artículos de esa fuente incluidos ese día (ej. "2 artículos", "1 artículo");
- el párrafo del resumen de esa fuente;
- debajo del párrafo, una fila por cada artículo que generó ese párrafo, con su miniatura (imagen destacada), su título (hasta dos líneas) y un indicador de navegación, que SHALL navegar al detalle del artículo al tocarla.

Si la fuente ya no existe localmente (ej. fue eliminada después de generar el resumen) o no tiene `iconUrl`, el ícono SHALL mostrar la inicial del `sourceName` guardado en la agrupación persistida, igual que `SourceIcon` en el resto de la app. Si un artículo no tiene imagen destacada, su miniatura SHALL ser un recuadro neutro con un ícono de documento. Los artículos referenciados que ya no existan localmente SHALL omitirse sin afectar al resto de las filas de ese bloque; el contador SHALL contar solo los artículos que se muestran.

Encima de las tarjetas, el sistema SHALL mostrar una cabecera con los íconos apilados (redondos, solapados) de las fuentes del resumen y el texto "N artículos de M fuentes", donde N es la cantidad de artículos del `DailySummary` y M la cantidad de fuentes de la agrupación persistida. Si el `DailySummary` no tiene agrupación persistida, la cabecera SHALL mostrar solo la cantidad de artículos resumidos, como antes de este cambio.

Cuando el `DailySummary` no tiene agrupación por fuente persistida (resúmenes generados antes de esa funcionalidad), o el nombre de un bloque no coincide con ninguna fuente de la agrupación persistida, el sistema SHALL mostrar el título en negrita y el texto de ese bloque sin tarjeta, sin ícono y sin filas de artículos.

El contenido del detalle SHALL tener un ancho máximo de aproximadamente 680pt, centrado, en cualquier ancho de pantalla. En la tab Resúmenes el detalle SHALL mostrarse sin barra superior propia, bajo la barra superior del shell principal, y SHALL incluir dentro del contenido la fecha del resumen en formato largo localizado (antes en el título de la barra). Abierto desde la tarjeta del Inbox, el detalle SHALL conservar su propia barra superior con ese título, como antes de este cambio.

#### Scenario: Ver el texto completo del resumen más reciente
- **WHEN** el usuario entra a la tab Resúmenes y existe al menos un `DailySummary`
- **THEN** el sistema muestra, sin ningún paso intermedio, el texto completo, la fecha y la cantidad de artículos del `DailySummary` más reciente

#### Scenario: La fecha aparece dentro del contenido en la tab
- **WHEN** se muestra el resumen en la tab Resúmenes
- **THEN** la fecha del resumen se muestra en formato largo localizado dentro del contenido, y no se agrega una segunda barra superior debajo de la del shell principal

#### Scenario: Detalle abierto desde el Inbox conserva su barra superior
- **WHEN** el usuario abre el resumen de hoy desde la tarjeta del Inbox
- **THEN** el detalle se muestra con su propia barra superior con el título "Resumen del {fecha}", como antes de este cambio

#### Scenario: Título de cada bloque en negrita
- **WHEN** se muestra el detalle de un `DailySummary`
- **THEN** el nombre de cada fuente (primera línea de cada bloque separado por línea en blanco) se muestra con estilo en negrita, distinguible del resto del párrafo

#### Scenario: Bloque emparejado se muestra como tarjeta con el ícono de la fuente
- **WHEN** el nombre de un bloque coincide con una fuente de la agrupación persistida y esa fuente existe localmente con `iconUrl`
- **THEN** el bloque se muestra como una tarjeta cuyo encabezado tiene el ícono de la fuente a la izquierda de su nombre en negrita, y a la derecha el texto con la cantidad de artículos ("2 artículos")

#### Scenario: Fuente eliminada conserva el bloque con la inicial
- **WHEN** el `sourceId` de un bloque ya no corresponde a ninguna fuente local (fue eliminada después de generar el resumen)
- **THEN** la tarjeta se muestra igual, con la inicial del `sourceName` guardado como ícono, sin error ni espacio vacío

#### Scenario: Cada artículo es una fila con miniatura
- **WHEN** la agrupación persistida indica que una fuente aportó uno o más artículos ese día y existen localmente
- **THEN** debajo del párrafo se muestra una fila por artículo con su miniatura, su título y un indicador de navegación, y tocarla navega al detalle de ese artículo

#### Scenario: Artículo sin imagen destacada
- **WHEN** un artículo referenciado no tiene imagen destacada
- **THEN** su fila muestra un recuadro neutro con un ícono de documento en lugar de la miniatura

#### Scenario: Artículo referenciado ya no existe localmente
- **WHEN** uno de los `articleIds` de la agrupación persistida ya no corresponde a ningún artículo local (fue eliminado en cascada al borrar su fuente)
- **THEN** el sistema omite la fila de ese artículo puntual sin afectar las demás filas del mismo bloque ni el resto de la pantalla, y el contador cuenta solo los artículos mostrados

#### Scenario: Cabecera con íconos apilados y conteo de fuentes
- **WHEN** el `DailySummary` tiene agrupación persistida con 12 artículos y 3 fuentes
- **THEN** encima de las tarjetas se muestran los íconos apilados de esas fuentes y el texto "12 artículos de 3 fuentes" en el idioma de la app, con la concordancia singular/plural correcta

#### Scenario: Resumen sin agrupación persistida se muestra como antes
- **WHEN** el `DailySummary` fue generado antes de la agrupación por fuente (sin `sourceBlocks`)
- **THEN** el sistema muestra los títulos de fuente en negrita y el texto de cada bloque, sin tarjetas, sin íconos, sin filas de artículos y con la cabecera de solo conteo de artículos

#### Scenario: Bloque que no empareja con ninguna fuente
- **WHEN** el nombre de un bloque no coincide con ninguna fuente de la agrupación persistida
- **THEN** ese bloque se muestra con su título en negrita y su texto, sin tarjeta, sin ícono y sin filas

#### Scenario: Bloque con etiqueta "Fuente:" se empareja y muestra sin la etiqueta
- **WHEN** el texto de un `DailySummary` ya guardado empieza un bloque con `Fuente: TechCrunch` y la agrupación persistida tiene una fuente llamada `TechCrunch` con 2 artículos
- **THEN** el sistema muestra `TechCrunch` en negrita (sin la etiqueta) en la tarjeta de esa fuente, y debajo del párrafo muestra una fila por cada uno de esos 2 artículos

#### Scenario: Etiqueta en otro idioma o con espacio antes de los dos puntos
- **WHEN** el primer renglón de un bloque es `Source: Stratechery` o `Source : Stratechery`, o `fuente: Stratechery` en minúsculas
- **THEN** el sistema se comporta igual que en el escenario anterior: ignora la etiqueta y empareja por el nombre `Stratechery`

#### Scenario: Una fuente cuyo nombre contiene dos puntos no se altera
- **WHEN** el primer renglón de un bloque es `Reuters: World News` y esa es exactamente la fuente persistida (no empieza con `Fuente`/`Source`)
- **THEN** el sistema NO quita nada de ese renglón, lo muestra completo y lo empareja por el nombre completo

#### Scenario: Ancho máximo en pantallas anchas
- **WHEN** el detalle se muestra en un ancho ≥840dp, ya sea embebido en el panel derecho del master-detail o a pantalla completa
- **THEN** las tarjetas y la cabecera se centran con un ancho máximo de aproximadamente 680pt, sin estirarse de borde a borde, y la barra superior y la persistencia de la selección se comportan igual que antes de este cambio
