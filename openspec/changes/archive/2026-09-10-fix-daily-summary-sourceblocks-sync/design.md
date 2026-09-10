## Context

Ver `proposal.md - Why` para el diagnóstico completo. En resumen: `DailySummaryModel.sourceBlocks` (`lib/core/data/models/daily_summary_model.dart:29`, serializado como `List<Map<dynamic, dynamic>>` con `sourceId`/`sourceName`/`articleIds`) se guarda correctamente en Hive al generar el resumen, pero `_summaryToRow`/`_summaryFromRow` (`lib/features/sync/domain/usecases/sync_user_data.dart:256-274`) no lo incluyen, y la tabla `daily_summaries` en Postgres no tiene columna para él. `_syncSummaries` sube y luego baja en el mismo ciclo (usando el `lastSyncedAt` previo a la subida), y `applyRemote` (`hive_summary_datasource.dart:36-37`) hace `put()` completo del modelo remoto sobre el local — así que el registro recién generado casi siempre pierde `sourceBlocks` en el primer sync posterior a su creación.

## Goals / Non-Goals

**Goals:**
- Que `sourceBlocks` viaje en la sincronización (subida y bajada) de `daily_summaries`, igual que el resto de los campos.
- Que un registro remoto sin `source_blocks` (resúmenes viejos, generados antes de este fix) no borre un `sourceBlocks` local ya presente.
- Cubrir esto con un test de regresión a nivel del usecase de sync.

**Non-Goals:**
- No se toca el prompt enviado a Gemini ni el formato de salida esperado (texto libre por fuente) — la investigación descartó eso como causa.
- No se toca el mecanismo de matching por nombre exacto en `summary_detail_screen.dart` — es una fragilidad real pero secundaria y fuera del alcance de este fix puntual. Puede abordarse en un change aparte si se decide.
- No se hace backfill de `sourceBlocks` para resúmenes ya generados y ya sincronizados sin ellos (dato irrecuperable: la agrupación original ya se perdió). Esos resúmenes seguirán mostrando el bloque sin chips, como ya contempla la spec ("resumen sin agrupación persistida").

## Decisions

**Columna nueva `source_blocks jsonb` en `daily_summaries`.** Se reutiliza la misma forma que ya usa `DailySummaryModel._sourceBlocksToMaps` (`[{sourceId, sourceName, articleIds}]`), serializada a JSON al subir y parseada de vuelta al bajar. Alternativa descartada: tres columnas relacionales (`daily_summary_sources`, etc.) — over-engineering para un campo que ya es opaco y de solo lectura para el resto del sistema; el patrón `jsonb` es consistente con cómo Hive ya lo guarda (mapas sueltos, no un modelo tipado propio).

**`applyRemote` no debe pisar `sourceBlocks` local con `null` si el remoto no lo trae.** En vez de agregar lógica de merge genérica al datasource, la corrección más simple y localizada es: cuando `_summaryFromRow` arma el `DailySummaryModel` a partir de una fila sin `source_blocks`, dejar ese campo en `null`; y en el datasource, al aplicar un remoto, si el modelo remoto trae `sourceBlocks == null` pero el registro local existente para ese `id` tiene `sourceBlocks` no nulo, conservar el valor local en vez de sobrescribirlo con `null`. Esto protege contra la clase de bug completa (cualquier campo nuevo que se agregue a futuro y tarde en llegar a la tabla remota), no solo contra este caso puntual. Alternativa descartada: hacer merge campo-por-campo genérico entre local y remoto en todo `applyRemote` — cambia la semántica de sync para todos los campos (el resto sí debe poder pisarse con `null`, ej. si el usuario borra contenido) y es más riesgoso que un caso especial acotado a `sourceBlocks`.

**Migración aditiva, sin backfill.** La columna nueva es nullable y no requiere default especial; los resúmenes existentes quedan con `source_blocks = null` (mismo comportamiento silencioso ya documentado en la spec para "resumen sin agrupación persistida").

## Risks / Trade-offs

- [Un resumen generado en una versión vieja de la app, sin `sourceBlocks` local, se sincroniza y baja en una versión nueva] → No hay regresión: el registro remoto tampoco tendrá `source_blocks` (la app vieja no lo sube), así que el comportamiento es el mismo que hoy — sin chips para ese resumen, sin crashear.
- [El caso especial en `applyRemote` para no pisar `sourceBlocks` con `null` podría enmascarar un borrado intencional futuro de `sourceBlocks`] → Hoy no existe ningún flujo que borre `sourceBlocks` intencionalmente después de creado el resumen (es inmutable una vez generado), así que no hay caso de uso legítimo que este trade-off rompa.
- [Tests de sync existentes que asumen la forma actual de `_summaryToRow`/`_summaryFromRow`] → Revisar y actualizar `test/unit/features/sync/` al tocar esas funciones.

## Migration Plan

1. Migración SQL aditiva (`ALTER TABLE daily_summaries ADD COLUMN source_blocks jsonb;`), sin downtime, sin backfill.
2. Deploy de la migración a `reevo-dev` primero, confirmar, luego a `reevo` (producción) — seguir la práctica ya establecida en `CLAUDE.md` de confirmar con el usuario a cuál(es) proyecto(s) desplegar.
3. Cambios de Flutter (`sync_user_data.dart`, datasource) se despliegan vía el flujo normal de PR — no requieren coordinarse en el mismo instante que la migración porque el campo es aditivo y opcional en ambos lados.
4. Rollback: si hiciera falta revertir, la columna puede quedar sin usarse sin romper nada (es nullable y no tiene constraint); no hace falta un `DROP COLUMN` de emergencia.
