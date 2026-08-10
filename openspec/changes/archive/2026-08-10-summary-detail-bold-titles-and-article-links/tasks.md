## 1. Modelo de datos

- [x] 1.1 Crear `SummarySourceBlock` en `lib/core/domain/entities/` (clase `Equatable` simple: `sourceId`, `sourceName`, `articleIds`).
- [x] 1.2 Agregar `List<SummarySourceBlock>? sourceBlocks` a `DailySummary` (entidad).
- [x] 1.3 Agregar `@HiveField(6) List<Map<dynamic, dynamic>>? sourceBlocks` a `DailySummaryModel`, con conversión Map↔`SummarySourceBlock` en `fromEntity`/`toEntity`.
- [x] 1.4 Correr `dart run build_runner build --delete-conflicting-outputs` para regenerar `daily_summary_model.g.dart`.

## 2. Generación del resumen

- [x] 2.1 En `GenerateDailySummary.execute()`, agrupar `todayArticles` por `sourceId` para armar `sourceBlocks` (id, nombre, lista de `articleIds`), en el mismo recorrido/lugar donde ya se arma el request a `_summaryGenerator.summarize`.
- [x] 2.2 Incluir `sourceBlocks` al construir el `DailySummary` que se persiste.

## 3. Pantalla de detalle

- [x] 3.1 En `SummaryDetailScreen`, parsear `summary.content` en bloques separados por línea en blanco (primera línea = nombre de fuente, resto = párrafo).
- [x] 3.2 Renderizar el nombre de fuente de cada bloque en negrita (`fontWeight: FontWeight.bold` o `titleSmall`/similar del theme) seguido del párrafo.
- [x] 3.3 Para cada bloque, buscar el `SummarySourceBlock` de `summary.sourceBlocks` cuyo `sourceName` coincida (trim, comparación exacta); si no hay `sourceBlocks` o no hay match, no mostrar ningún link para ese bloque.
- [x] 3.4 Resolver los artículos del bloque emparejado vía `ArticleRepository.getArticleById` (a través de un use case existente o uno nuevo simple), descartando los que devuelvan `null`.
- [x] 3.5 Si queda un solo artículo resuelto, mostrar un link directo a `/article/:id` con su título. Si quedan varios, mostrar una fila de chips (`Wrap`) con el título truncado de cada uno, cada uno navegando a su detalle.

## 4. Tests

- [x] 4.1 Unit test de `GenerateDailySummary`: verifica que el `DailySummary` persistido incluye `sourceBlocks` con los `articleIds` correctos agrupados por fuente.
- [x] 4.2 Unit test de `DailySummaryModel`: round-trip `fromEntity`/`toEntity` preserva `sourceBlocks`, y `toEntity()` sobre un modelo sin ese campo (simulando dato viejo) devuelve `sourceBlocks: null` sin error.
- [x] 4.3 Widget test de `SummaryDetailScreen`: el nombre de cada fuente se muestra en negrita.
- [x] 4.4 Widget test de `SummaryDetailScreen`: con `sourceBlocks` y un solo artículo por fuente, se muestra un link que navega al detalle de ese artículo.
- [x] 4.5 Widget test de `SummaryDetailScreen`: con `sourceBlocks` y varios artículos para una fuente, se muestran varios links/chips, cada uno navegando al artículo correspondiente.
- [x] 4.6 Widget test de `SummaryDetailScreen`: sin `sourceBlocks` (resumen "viejo"), se muestra el título en negrita sin ningún link.
- [x] 4.7 Widget test de `SummaryDetailScreen`: un `articleId` que no resuelve a ningún artículo local se omite sin romper el resto de los links del bloque.

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` sin warnings.
- [x] 5.2 Correr `flutter test` y confirmar que toda la suite pasa.
- [x] 5.3 Generar un resumen real en un dispositivo/emulador y confirmar visualmente: negrita, link único, chips múltiples, y que un resumen generado antes del cambio (si hay alguno persistido) se sigue viendo bien sin links.
