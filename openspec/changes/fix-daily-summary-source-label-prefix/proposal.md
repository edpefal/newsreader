## Why

El resumen diario automático de hoy del usuario de prod (2 artículos de TechCrunch) no mostró el nombre de la fuente en negrita ni los links para abrir los artículos, aunque el servidor guardó correctamente `source_blocks` con esos 2 artículos. La causa: el prompt de `generate-daily-summaries` etiqueta cada grupo de entrada como `Fuente: <nombre>` (`prompt.ts`, `buildPrompt`), y Gemini copió esa etiqueta al texto generado — el `content` quedó con `Fuente: TechCrunch` como primera línea en vez de `TechCrunch`, a pesar de que la instrucción de salida le pide explícitamente que no la repita.

El cliente identifica a qué fuente pertenece cada bloque comparando la primera línea del bloque contra `sourceName` por igualdad exacta (`summary_detail_screen.dart`, `_matchingSourceBlock`). `"Fuente: TechCrunch" != "TechCrunch"`, así que no hay emparejamiento, `sourceBlock` queda `null` y no se dibuja ningún link ni chip debajo del párrafo. El fallo es intermitente (depende de si el modelo copia o no la etiqueta; el resumen del día anterior salió bien) y puede repetirse con cualquier usuario.

## What Changes

- **Cliente** (`summary_detail_screen.dart`): normalizar el título parseado de cada bloque antes de compararlo con `sourceName`, quitando un prefijo de etiqueta `Fuente:` / `Source:` / `Source :` (es/en/fr, con o sin espacio antes de los dos puntos, sin distinguir mayúsculas). El título que se muestra en negrita también se muestra sin ese prefijo. Esto repara de inmediato los resúmenes ya guardados (como el de hoy en prod) sin regenerarlos ni migrar datos.
- **Servidor** (`supabase/functions/generate-daily-summaries`): limpiar el mismo prefijo de la primera línea de cada bloque del texto generado antes de persistirlo en `daily_summaries.content`. Así los resúmenes nuevos quedan con el formato que ya documenta la capability (`<nombre de la fuente>\n<párrafo>`). El prompt enviado a Gemini no cambia: la limpieza determinista es la garantía; reescribir el rótulo de entrada sería una apuesta sobre el comportamiento no determinista del modelo que no se puede verificar offline.
- Sin texto nuevo visible al usuario (no hay claves de i18n nuevas) y sin cambios de layout: no cambia la estructura de la pantalla de detalle ni su compatibilidad con el layout adaptativo de iPad.

## Capabilities

### New Capabilities
<!-- Ninguna -->

### Modified Capabilities
- `daily-summaries`: el requirement "Detalle de un resumen" pasa a tolerar un prefijo de etiqueta (`Fuente:`/`Source:`) en el nombre de fuente de cada bloque al emparejarlo con la agrupación persistida; y se agrega un requirement que fija que el texto persistido de cada bloque empieza con el nombre de la fuente sin ninguna etiqueta.

## Impact

- `lib/features/summaries/presentation/screens/summary_detail_screen.dart` (normalización del título; hoy `_parseBlocks` / `_matchingSourceBlock`).
- Posible helper puro compartido para normalizar títulos de bloque, con tests unitarios.
- `supabase/functions/generate-daily-summaries/prompt.ts` y `index.ts` (limpieza del prefijo del texto generado y etiqueta de entrada del prompt), más sus tests de Deno.
- Despliegue de la Edge Function `generate-daily-summaries`: el repo la tiene linkeada a prod (`reevo`) por defecto; hay que confirmar con el usuario a cuál(es) proyecto(s) desplegar (`reevo` prod / `reevo-dev`) antes de dar el change por terminado. Sin migraciones de base de datos.
- Los resúmenes ya guardados no se reescriben: los repara la normalización del lado cliente.
