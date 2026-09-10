## 1. Migración de base de datos

- [x] 1.1 Crear migración SQL que agrega `source_blocks jsonb` (nullable) a `daily_summaries`
- [x] 1.2 Aplicar la migración a `reevo-dev` y confirmar
- [x] 1.3 Confirmar con el usuario si corresponde aplicarla también a `reevo` (prod) en este mismo change, y hacerlo si así se decide (usuario confirmó: aplicar a ambos)

## 2. Sincronización (Flutter)

- [x] 2.1 Incluir `sourceBlocks` (serializado a JSON) en `_summaryToRow` (`lib/features/sync/domain/usecases/sync_user_data.dart`)
- [x] 2.2 Reconstruir `sourceBlocks` desde `row['source_blocks']` en `_summaryFromRow`, dejándolo en `null` si la fila no trae el campo
- [x] 2.3 En el datasource local (`hive_summary_datasource.dart`), al aplicar un remoto cuyo `sourceBlocks` es `null`, conservar el `sourceBlocks` del registro local existente en vez de sobrescribirlo con `null`

## 3. Tests

- [x] 3.1 Test unitario de `sync_user_data.dart` que reproduce el escenario: generar resumen con `sourceBlocks` → sincronizar (subida + bajada en el mismo ciclo) → verificar que `sourceBlocks` sigue presente localmente
- [x] 3.2 Test unitario para el caso "remoto sin source_blocks no borra el local ya existente"
- [x] 3.3 Actualizar tests existentes de `_summaryToRow`/`_summaryFromRow` que asuman la forma anterior de la fila, si los hay (no había tests previos cubriendo esa forma; no hizo falta actualizar ninguno)

## 4. Verificación

- [x] 4.1 Correr `flutter analyze` sin warnings nuevos
- [x] 4.2 Correr `flutter test` completo
- [x] 4.3 Confirmar con el usuario a qué proyecto(s) de Supabase desplegar (solo dev, o también prod) antes de dar el change por terminado (aplicada a ambos)
