## Context

`SummaryDetailScreen` (`features/summaries/presentation/screens/summary_detail_screen.dart`) parsea `DailySummary.content` en bloques, empareja cada bloque con un `SummarySourceBlock` por nombre (tras `normalizeSummaryBlockTitle`) y resuelve los artículos con `ResolveSummaryArticles`. Todo vive en un solo archivo con varias clases privadas, lo que choca con la convención de una clase por archivo. Ver `proposal.md` para la motivación.

Restricciones:
- Un feature no importa de otro: `summaries` no puede importar de `reader` (donde vive `kReaderMaxContentWidth = 680`) ni de `inbox`.
- Hive solo se toca desde datasources; el acceso a fuentes va por `SourceRepository.getSourceById`.
- `SourceIcon` (`core/widgets/`) ya implementa ícono chamfered con fallback a la inicial en óxido; `NewsSource.iconUrl` es opcional.
- El detalle ya se monta en dos rutas (`/` desde el Inbox y `/summaries/:date`) dentro del layout adaptativo; el chrome de pantalla no cambia en este change.

## Goals / Non-Goals

**Goals:**
- Resolver el ícono de cada fuente sin acoplar la presentación a repositorios.
- Dividir la pantalla en widgets de una clase por archivo, sin cambiar el parseo ni el emparejamiento existentes.
- Degradar sin errores ante fuente eliminada, artículo eliminado, o resumen sin `sourceBlocks`.

**Non-Goals:**
- No tocar servidor, modelo `DailySummary`/`SummarySourceBlock`, sync ni el prompt de la IA.
- No rediseñar la tarjeta del Inbox ni la lista de resúmenes.
- No cambiar `SourceIcon` ni su fallback.

## Decisions

**1. Use case `ResolveSummarySources` en lugar de leer fuentes desde el widget.**
Recibe `List<String>` de `sourceId` y devuelve `Map<String, NewsSource>` descartando en silencio los ids que no existan, igual que `ResolveSummaryArticles`. Se inyecta por constructor en `SummaryDetailScreen` y se registra en `injection.dart`. Alternativa: usar `GetSources` y filtrar en memoria; descartada porque trae todas las fuentes para necesitar unas pocas y obliga a la pantalla a conocer más de lo necesario.

**2. Resolver fuentes y artículos en paralelo, un solo `setState`.**
Ambas resoluciones son independientes y locales (Hive). Se lanzan con `Future.wait` y se aplican en un solo `setState`, para que la tarjeta no pinte primero con inicial y luego "salte" al ícono real. Mientras no resuelven, se muestra el bloque con la inicial del `sourceName` (que ya está en el bloque), así el primer frame nunca queda vacío. Alternativa: resolver por bloque con `FutureBuilder`; descartada por más parpadeo y más rebuilds.

**3. División en widgets propios bajo `features/summaries/presentation/widgets/`.**
`summary_header.dart` (avatares apilados + conteo), `summary_source_card.dart`, `summary_article_row.dart`, `summary_plain_block.dart` (el bloque sin tarjeta, igual al de hoy) y `summary_block_parser.dart` (la lógica de `_parseBlocks`, que hoy es una función privada del screen). El screen queda como orquestador. Se mantiene sin cambios `normalizeSummaryBlockTitle`.

**4. Avatares de cabecera redondos, de tarjeta chamfered.**
La cabecera usa un avatar circular compacto (ícono recortado en círculo, borde del color de fondo para el solapamiento); la tarjeta usa `SourceIcon` tal cual. Para no duplicar la lógica de fallback, el avatar de la cabecera envuelve el mismo `CachedNetworkImageWidget` y el mismo color de inicial que `SourceIcon`; si el costo de duplicar es mayor que el beneficio, se aceptará un `SourceIcon` chamfered en la cabecera. Se muestran como máximo 4 avatares, y un "+N" si hay más fuentes.

**5. Contador de texto y conteo cuentan solo artículos resueltos.**
El contador de la tarjeta es texto (`summaryListArticleCount`, ya existente, no una insignia: un número suelto no dejaba claro a qué se refería) y usa la cantidad de artículos que efectivamente se muestran, no `articleIds.length`, para que coincida con las filas. Mientras los artículos no se han resuelto, usa `articleIds.length` para no parpadear de 0 a N. El "N artículos de M fuentes" de la cabecera usa `DailySummary.articleCount` y `sourceBlocks.length`: es el conteo del resumen, no de lo que sobrevive localmente.

**6. Miniatura con `NetworkImageWidget`; fallback propio.**
La fila usa `NetworkImageWidget` (abstracción de `cached_network_image`) con `Article.imageUrl`; sin imagen o con error de carga, un recuadro con `colorScheme.surfaceContainerHighest` y `Icons.article_outlined`. Alternativa: usar la inicial de la fuente como fallback; descartada porque la tarjeta ya la muestra arriba.

**7. Ancho máximo local de 680.**
Se define una constante privada en el widget de contenido del detalle (`ConstrainedBox` centrado), en vez de importar `kReaderMaxContentWidth` desde `reader`. Alternativa: mover la constante a `core/`; es el movimiento correcto si un tercer feature la necesita, pero tocaría `reader` y excede este change.

**8. Textos.**
Una clave nueva `summaryDetailHeaderCount` con dos parámetros plurales (artículos y fuentes). ICU admite dos `plural` en un mismo mensaje; si `gen-l10n` lo rechaza, se parte en dos claves y se concatenan con un conector localizado. La clave existente `summaryDetailArticleCount` queda para el caso sin `sourceBlocks`.

## Risks / Trade-offs

- [Dos plurales en un mensaje ICU pueden no traducirse bien al francés] → Revisar a mano `app_fr.arb` y, si hace falta, partir en dos claves (ver decisión 8).
- [Saltos de layout al llegar las resoluciones asíncronas] → Reservar tamaño fijo para ícono y miniatura (40×40 / 30×30) y pintar siempre con el fallback desde el primer frame.
- [Resúmenes con muchas fuentes alargan el scroll] → Aceptable; las tarjetas son livianas y la lista usa `SingleChildScrollView` como hoy. Si alguna vez se ven decenas de fuentes, pasar a `ListView.builder`.
- [El nombre del bloque no empareja con `sourceName` y la tarjeta no aparece] → Es la degradación ya especificada (bloque plano). No cambia el algoritmo de emparejamiento.
- [Contraste del texto sobre el encabezado tintado en modo oscuro] → Usar colores del `ColorScheme`/`ReevoAccent` en vez de hex fijos, y comprobarlo en ambos temas al implementar.

## Migration Plan

Solo cliente, sin migración de datos ni de servidor. Se publica con la siguiente versión de la app. Rollback: revertir el PR; los datos no cambian.
