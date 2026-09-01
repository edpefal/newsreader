## Context

Ver `proposal.md` para el porqué. Este change se decidió en una sesión de exploración (`/opsx:explore`) donde primero se consideró un approach de generación automática (mañana/tarde, horario configurable), descartado porque el PRD declara explícitamente fuera de alcance las notificaciones push y el fetch en background sin acción del usuario (PRD.md sección 8) — sin push, generar automático no le aporta nada perceptible al usuario frente a un botón manual.

`ai-usage-budget` hoy es un pool de 30,000 palabras/día compartido por dos features independientes: `daily-summaries` (una llamada grande, todos los artículos de hoy juntos) y `article-summaries`+`article-mentions` (muchas llamadas chicas, una por artículo que el usuario elige resumir individualmente). Backends distintos (`supabase/functions/summarize-articles/` vs `supabase/functions/summarize-article/`), lo que hace viable separar el gate de una sin tocar la otra.

## Goals / Non-Goals

**Goals:**
- Reemplazar el gate de palabras de `daily-summaries` por un límite simple de una generación por día de servidor.
- Eliminar la funcionalidad de "Regenerar" del resumen diario y su diálogo de confirmación, que dejan de tener sentido bajo el nuevo límite.

**Non-Goals:**
- No se toca `article-summaries` ni `article-mentions` — siguen con el presupuesto de palabras compartido tal cual está.
- No se cambia el modelo de datos de `DailySummary` — sigue siendo una fila por fecha.
- No se agrega generación automática, horario configurable, ni notificaciones push — quedó descartado en la exploración previa.

## Decisions

- **Chequeo de "ya generado hoy" en vez de un contador nuevo**: en lugar de crear una tabla de conteo análoga a `ai-usage-budget`, el backend de `summarize-articles` puede chequear directamente si ya existe un `DailySummary` para `(user_id, fecha_de_hoy_server)` antes de invocar la API de IA — la tabla de resúmenes ya es la fuente de verdad de "qué días tienen resumen", no hace falta un contador separado. Esto es más simple que portar el mecanismo de `ai-usage-budget` (que fue diseñado para contar palabras, no para un booleano de una sola vez).
- **Chequeo e inserción deben ser atómicos igual que hoy `ai-usage-budget`**: dos solicitudes concurrentes del mismo usuario el mismo día no deben poder generar dos resúmenes — se resuelve con una constraint de unicidad `(user_id, date)` a nivel de base de datos sobre la tabla de `DailySummary` (si no existe ya) más manejo del error de constraint violada como "ya generado hoy", en vez de un chequeo-y-luego-insert no atómico.
- **UI**: se elimina toda la lógica de `wouldRegenerateWithSameArticles` y el diálogo `_confirmRegenerate` en `summaries_screen.dart`/`summaries_cubit.dart` — ya no hay ningún camino que lleve a esos métodos. El botón pasa a tener solo dos estados relevantes además de deshabilitado-sin-artículos: "Crear resumen" (habilitado) y deshabilitado con indicador de "ya generado hoy".
- **Claves de localización a eliminar**: `summariesRegenerateTodayButton`, `summariesRegenerateConfirmTitle`, `summariesRegenerateConfirmBody`, `summariesRegenerateConfirmButton`, en los 3 `.arb`. Se agrega una clave nueva para el indicador de "ya generado hoy" (a definir el texto exacto en `/opsx:apply`, siguiendo español neutro con tuteo).

## Risks / Trade-offs

- [Perder la posibilidad de regenerar si aparecen artículos importantes más tarde en el día] → Aceptado conscientemente por el usuario: es exactamente el trade-off que pidió (simplicidad y previsibilidad del límite sobre flexibilidad de regenerar).
- [Un usuario que genera el resumen muy temprano en el día se queda sin poder actualizarlo aunque falten la mayoría de los artículos del día] → Mismo trade-off aceptado; no se agrega ninguna advertencia adicional en el momento de generar más allá de la que ya existe (ninguna, hoy tampoco advierte "quedate esperando más artículos").

## Open Questions

- Texto exacto del indicador de "ya generado hoy" en los 3 idiomas — se resuelve en `/opsx:apply` siguiendo las convenciones de i18n del proyecto (no cambia el approach ni el task breakdown).

## Nota de implementación (resuelta en `/opsx:apply`)

El chequeo de "ya generado hoy" en `summarize-articles` es un `SELECT` contra `daily_summaries` filtrado por `user_id` + rango del día UTC en curso, no un `INSERT` de reserva antes de invocar a Gemini. Se descartó la reserva por `INSERT` porque el `id` real de cada `DailySummary` lo genera el cliente a partir de su fecha local (`dateKey`), mientras que el backend solo conoce el día de servidor (UTC) — una reserva con un `id` sintético distinto habría dejado filas huérfanas en `daily_summaries` que además se propagan a otros dispositivos vía `SyncUserData.fetchChangedSince`, ensuciando la pantalla de Resúmenes con entradas vacías. La constraint `(user_id, date)` agregada en la migración queda como defensa de integridad a nivel de base de datos (evita dos filas para el mismo usuario y fecha), pero no se maneja una violación de esa constraint dentro de `summarize-articles` porque esa función nunca inserta en `daily_summaries` — el único camino de escritura sigue siendo `SyncUserData`/`CloudSyncClient.upsert`, que ya es un upsert por `id` y no dispara esa constraint en el flujo normal (un mismo dispositivo deriva `id` y `date` de la misma fecha, así que nunca hay dos `id` distintos para el mismo `(user_id, date)`). El SELECT previo a Gemini cubre todos los escenarios de aceptación de la spec; la ventana de carrera entre dos solicitudes concurrentes del mismo usuario queda como riesgo residual aceptado (de la misma naturaleza que el resto de los trade-offs de simplicidad de este change), en vez de introducir una segunda tabla de reserva o filas huérfanas.
