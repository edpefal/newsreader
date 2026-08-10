## Context

`GenerateDailySummary.execute()` (`lib/features/summaries/domain/usecases/generate_daily_summary.dart`) ya arma `todayArticles.map((a) => (title, excerpt, sourceName))` para mandarle al backend (`summarize-articles`, que agrupa por `sourceName` y le pide a Gemini un párrafo por fuente). Esa agrupación por fuente se arma y se descarta en la misma función — nunca se persiste. `DailySummary` (entidad + `DailySummaryModel` Hive, `typeId: 2`) solo guarda el `content` resultante como string. `SummaryDetailScreen` lo renderiza como un único `Text` plano. Ver proposal.md - Why.

## Goals / Non-Goals

**Goals:**
- Persistir la agrupación por fuente (`sourceId`, `sourceName`, `articleIds`) en el mismo momento en que ya se calcula, sin tocar el prompt ni la llamada a `summarize-articles`.
- Parsear `content` en bloques y renderizar título en negrita + links a artículos, con degradación segura para resúmenes viejos o artículos ya inexistentes.

**Non-Goals:**
- No se cambia el formato de salida que le pedimos a Gemini (sigue siendo "nombre de fuente + párrafo, separados por línea en blanco").
- No se agrega ningún nuevo `HiveType`/typeId — el campo nuevo usa los tipos nativos que Hive CE serializa sin adapter (`List`/`Map` de tipos primitivos).
- No se resuelve el caso de que la IA altere levemente el nombre de una fuente entre el texto generado y el nombre real (fuera de control del cliente); si no matchea, simplemente no se muestra el link para ese bloque.

## Decisions

- **Nuevo campo `List<Map<dynamic, dynamic>>? sourceBlocks` en `DailySummaryModel`, `@HiveField(6)`**: Hive CE serializa `List`/`Map` de tipos primitivos sin necesitar un `TypeAdapter` propio (a diferencia de agregar una clase nueva, que sí requeriría un `typeId` nuevo). Nullable para que los resúmenes ya guardados (sin este campo) sigan deserializando sin migración de datos. Requiere `dart run build_runner build` para regenerar `daily_summary_model.g.dart`.
- **Estructura de cada entrada**: `{'sourceId': String, 'sourceName': String, 'articleIds': List<String>}`. En el dominio (`DailySummary`), se expone como un tipo propio `SummarySourceBlock` (clase simple con `Equatable`, sin dependencia de Hive) para no filtrar tipos de infraestructura hacia `domain/` — el mapeo Map↔`SummarySourceBlock` vive en `DailySummaryModel.fromEntity`/`toEntity`, igual que el resto de los campos.
- **Captura en `GenerateDailySummary.execute()`**: se arma `sourceBlocks` agrupando `todayArticles` por `sourceId` (no por nombre, para tener el id real) en el mismo `Map` que ya se usa implícitamente al construir el request — mismo lugar, mismo momento, un solo recorrido adicional sobre `todayArticles`.
- **Emparejamiento en `SummaryDetailScreen` por nombre, no por índice**: el prompt le pide a Gemini "una línea con el nombre de la fuente tal cual aparece" (ya un requisito existente), pero no hay garantía de que el orden de los bloques generados coincida con el orden de `sourceBlocks`. Matchear por nombre (`block.title.trim() == sourceBlock.sourceName`) es más robusto que por posición.
- **Resolución de artículos vía `ArticleRepository.getArticleById`** (ya existe): por cada `articleId` del bloque emparejado, se busca el artículo para obtener su título y confirmar que sigue existiendo; los que devuelven `null` (cascade-delete de una fuente borrada) se excluyen de la lista de links sin lanzar error.
- **Parseo de `content` por doble salto de línea**: separa en bloques `[nombreFuente, párrafo]`; es el mismo contrato que ya exige el prompt de `summarize-articles` ("Dejá una línea en blanco entre cada fuente"), así que no es una asunción nueva, solo se empieza a aprovechar en el cliente.

## Risks / Trade-offs

- [Si Gemini no respeta el formato exacto (ej. omite la línea en blanco entre fuentes, o cambia levemente el nombre) el parseo o el matcheo pueden fallar para ese bloque] → Mitigación: fallback silencioso a "sin negrita especial / sin link" para el bloque no reconocible, nunca un crash; el resto de los bloques bien formados se renderizan igual.
- [Resúmenes con muchos artículos de una misma fuente en un día podrían generar una fila de chips larga] → Mitigación: `Wrap` para que los chips salten de línea; no se pone límite artificial porque en la práctica un usuario no tiene decenas de artículos de una sola fuente en un solo día (límite de fuentes ilimitado, pero volumen diario por fuente es bajo).
