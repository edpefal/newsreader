## Context

Cuatro pantallas construyen listas de ítems: inbox (`AnimatedList`), archivo/favoritos/detalle de fuente (`ListView.builder`, mismo patrón de items intercalados con `DateSeparator`), y fuentes (`ListView.builder` de `_SourceTile`). Ninguna usa `separatorBuilder`/`ListView.separated`; el único espacio actual viene del padding intrínseco de `ListTile`. `ArticleInboxTile` (en `features/inbox/presentation/widgets/`) es el tile compartido por inbox, archivo, favoritos y detalle de fuente — ya se importa cross-feature hoy (deuda técnica preexistente, fuera de alcance de este change). `AnimatedList` no soporta `separatorBuilder`, así que cualquier solución basada en separadores de `ListView` no cubriría el inbox.

## Goals / Non-Goals

**Goals:**
- Un único punto de cambio por tile compartido (`ArticleInboxTile`, `_SourceTile`) que funcione sin importar si el contenedor es `AnimatedList` o `ListView.builder`.
- Mismo valor de espaciado en las cuatro listas de artículos y en la de fuentes.

**Non-Goals:**
- No se resuelve la deuda arquitectónica de `ArticleInboxTile` importado cross-feature (se documenta pero no se mueve a `core/widgets/` en este change).
- No se toca `import_opml_screen.dart` (lista de previsualización de importación, no es una de las listas "de la app" a las que refiere el usuario).
- No se introduce un design token nuevo de spacing en el theme; se usa una constante local simple.

## Decisions

**Envolver cada tile en un `Padding` vertical propio, en vez de usar `separatorBuilder`/`ListView.separated`.**
Alternativa descartada: convertir los `ListView.builder` a `ListView.separated` con un `SizedBox` separador. Se descarta porque el inbox usa `AnimatedList`, que no tiene equivalente `separatorBuilder` — habría que duplicar la lógica de espaciado con dos mecanismos distintos (separator para unos, algo ad-hoc para el otro). Envolver el propio tile en `Padding(vertical: X)` funciona igual en ambos tipos de lista y centraliza el valor de espaciado en el widget compartido.

**Valor de espaciado: `8.0` de padding vertical por tile (16px de separación visual total entre dos tiles consecutivos).**
Suficiente para que el espacio sea perceptible sin duplicar la altura de cada fila. Se define como constante privada en cada tile (`_verticalSpacing`), no en el theme global, porque es un detalle de layout de estos dos widgets puntuales.

**No envolver `DateSeparator` con el mismo padding.**
`DateSeparator` ya tiene su propio padding (`fromLTRB(16, 12, 4)`) pensado como separador de sección; se deja igual para no duplicar espacio entre un encabezado de fecha y el primer artículo del grupo.

## Risks / Trade-offs

[Padding en el tile en vez de separador entre ítems] → El primer y último ítem de la lista también ganan padding extra (arriba/abajo), no solo el espacio "entre" ítems. Es un efecto visual menor y aceptable (consistente con cómo ya se ve el primer `SizedBox(height: 16)` del inbox); no requiere mitigación.

[Duplicación del valor de spacing entre `ArticleInboxTile` y `_SourceTile`] → Ambos widgets fijan `8.0` de forma independiente. Si más adelante se agrega una tercera lista, conviene extraer una constante compartida en `core/`; no se hace ahora para no introducir abstracción prematura por dos usos.
