## Why

El resumen diario persiste una agrupación por fuente (`sourceBlocks`) que la pantalla de detalle usa para mostrar los chips de "artículos de origen" de cada bloque. Pero la sincronización con Supabase (`sync_user_data.dart`) no incluye `sourceBlocks` al subir ni al bajar registros de `daily_summaries`, y la tabla remota tampoco tiene columna para guardarlos. Como la sincronización sobrescribe por completo el registro local (`applyRemote`), en cuanto corre el siguiente ciclo de sync después de generar un resumen — algo que pasa casi de inmediato, porque `InboxCubit` dispara `sync_user_data` en varios puntos incluyendo abrir o refrescar el Inbox — el resumen recién generado pierde sus `sourceBlocks` en el dispositivo, y los chips desaparecen de forma silenciosa y permanente para ese resumen, sin ningún error visible ni log.

## What Changes

- Agregar una columna `source_blocks` (JSON) a la tabla `daily_summaries` en Supabase.
- Incluir `sourceBlocks` en la fila que sube `_summaryToRow` y en el modelo que reconstruye `_summaryFromRow` en `sync_user_data.dart`, serializando/deserializando la misma estructura que ya usa `DailySummaryModel` localmente.
- Verificar que el flujo de subida-luego-bajada dentro de un mismo ciclo de sync (`_syncSummaries`) no vuelva a pisar un registro recién subido con una versión sin `sourceBlocks` (regresión de esta clase no debe poder repetirse silenciosamente).
- Agregar un test de sync que reproduzca el escenario exacto (generar resumen → sincronizar → verificar que `sourceBlocks` sigue presente localmente) para que una futura regresión falle en CI en vez de pasar desapercibida.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `daily-summaries`: la agrupación por fuente (`sourceBlocks`) que se persiste junto al resumen debe sobrevivir un ciclo de sincronización con la nube (subida y bajada), no solo la persistencia local inicial.
- `cloud-sync`: la sincronización de `daily_summaries` debe incluir el campo de agrupación por fuente (`source_blocks`) tanto al subir como al bajar cambios, y la tabla remota debe tener la columna correspondiente.

## Impact

- `supabase/migrations/` — nueva migración que agrega la columna `source_blocks` a `daily_summaries`.
- `lib/features/sync/domain/usecases/sync_user_data.dart` — `_summaryToRow` y `_summaryFromRow`.
- `lib/core/data/models/daily_summary_model.dart` — posible ajuste si hace falta un helper de serialización compartido para `sourceBlocks` entre Hive y la fila de Supabase.
- `test/unit/features/sync/` — nuevo test cubriendo el round-trip de sync con `sourceBlocks`.
- No afecta el prompt enviado a Gemini ni el parseo en `summary_detail_screen.dart` — la causa no está ahí.
