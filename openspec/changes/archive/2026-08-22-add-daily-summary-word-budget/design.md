## Context

El único gate que existe hoy antes de invocar a Gemini en `summarize-articles` es el entitlement de suscripción (`entitlements`, `user_id` → `is_active`, RLS `select_own`, escrita solo por `service_role` vía `superwall-webhook`). No hay ninguna tabla ni mecanismo de conteo de uso.

El cliente Flutter no habla directo con Postgres salvo a través de dos vías ya establecidas: `AuthClient` (Supabase Auth) y `CloudSyncClient` (lectura/escritura genérica de filas de usuario vía el SDK de Supabase, usado hoy para `sources`/`articles`/`daily_summaries`, siempre bajo RLS `user_id = auth.uid()`). Todo lo demás pasa por edge functions vía `HttpClient`. Ver `proposal.md` para la motivación completa.

## Goals / Non-Goals

**Goals:**
- El presupuesto se hace cumplir del lado del servidor — un cliente modificado o múltiples dispositivos de la misma cuenta no pueden saltarse el límite.
- El chequeo y el incremento son una sola operación atómica (sin ventana de carrera entre "leo cuánto llevo" y "escribo cuánto llevo" si hay dos requests concurrentes).
- `AiUsagePolicy` es genérica: un futuro segundo consumidor (resumir artículo individual) la reusa sin tocarla, y sin que el presupuesto viva acoplado a la tabla de `daily_summaries`.

**Non-Goals:**
- No hay forma de pedir presupuesto extra el mismo día (corte duro, ver decisión ya tomada en la exploración previa).
- El "día" del presupuesto es el día del servidor (UTC), no el día local del usuario — ver Riesgos.
- No se agrega un mecanismo de limpieza/purga programada de filas viejas (la tabla tiene una fila por usuario, se sobrescribe in-place cada día, no crece).

## Decisions

### 1. Una tabla con una fila por usuario, no una fila por día

```
ai_usage_daily (
  user_id   uuid primary key references auth.users(id) on delete cascade,
  day       date not null,
  words_used integer not null default 0,
  updated_at timestamptz not null default now()
)
```

Una sola fila por usuario (no una tabla que acumula una fila nueva por día) — se resetea in-place cuando cambia `day`. Evita tener que purgar filas viejas y evita que `CloudSyncClient.fetchChangedSince` (que pagina y ordena por `updated_at`) tenga que filtrar entre muchas filas históricas para encontrar la de hoy.

**Alternativa considerada**: una fila por `(user_id, day)`. Se descarta para la v1 porque no hay ningún caso de uso que necesite el historial de días anteriores todavía (no hay una pantalla de "tu consumo de los últimos 30 días"), y agrega complejidad de purga sin beneficio actual.

### 2. Chequeo + incremento como una función de Postgres (`SECURITY DEFINER`), no como lectura+escritura desde el edge function

```sql
create function check_and_record_ai_usage(p_words integer, p_daily_limit integer)
returns table (allowed boolean, words_used integer)
security definer
```

La función usa `auth.uid()` internamente (nunca un `user_id` que mande el caller) para identificar la fila, resetea `words_used` a 0 si `day <> current_date`, y hace el chequeo-e-incremento en un único `UPDATE ... RETURNING` — atómico por el locking de fila de Postgres, sin necesidad de una transacción explícita ni de lógica de reintento en Deno.

**Alternativa considerada**: leer la fila desde el edge function, decidir en JS si permite la solicitud, y hacer un segundo `UPDATE` para incrementar. Se descarta porque abre una ventana de carrera real entre el read y el write si el mismo usuario dispara dos solicitudes casi al mismo tiempo (ver el requirement de "chequeo e incremento atómicos" en la spec) — dos requests podrían leer el mismo valor "todavía dentro del presupuesto" antes de que ninguna de las dos escriba.

`summarize-articles` cuenta las palabras de la solicitud (títulos + contenido de cada artículo, separando por espacios en blanco — mismo criterio simple usado para estimar el presupuesto en la exploración previa, sin necesidad de un tokenizer real) y llama a esta función ANTES de invocar a Gemini. Si `allowed = false`, responde con el nuevo error distintivo sin invocar a Gemini.

### 3. El cliente lee el estado de uso reusando `CloudSyncClient`, no un edge function nuevo

`SupabaseAiUsagePolicy` (implementación de `AiUsagePolicy` en `core/ai_usage/`) llama a `CloudSyncClient.fetchChangedSince('ai_usage_daily', null)` (mismo mecanismo genérico ya usado para `sources`/`articles`/`daily_summaries`, bajo la misma RLS `select_own`) y toma la única fila que devuelve para armar el estado (`wordsUsed`, `wordLimit`, `resetsAt`). No se persiste en Hive — se pide fresco cada vez que la pantalla de Resúmenes lo necesita, porque el valor cambia del lado del servidor sin que el cliente lo sepa.

```dart
abstract class AiUsagePolicy {
  Future<AiUsageStatus> getStatus();
}

class AiUsageStatus {
  final int wordsUsed;
  final int wordLimit;
  final DateTime resetsAt;
}
```

`AiUsagePolicy` NO tiene un método `canGenerate()`/`recordUsage()`: la autoridad real vive en `check_and_record_ai_usage` (server-side), así que un chequeo previo del lado del cliente sería solo asesorio y podría quedar stale entre que se muestra y que efectivamente se dispara la generación. La UI usa `getStatus()` tanto para el medidor como para decidir si deshabilita el botón (`wordsUsed >= wordLimit`), y maneja el rechazo real (si igual se dispara) a través del mismo camino de error que cualquier otra falla de `summarize-articles`.

### 4. Nuevo `AppErrorCode.aiUsageLimitReached`

Se agrega al enum existente y se localiza en los 3 idiomas soportados (mismo patrón que el resto de `AppErrorCode`), para que `SummaryGenerationError` lo distinga de `generationFailed`/`noArticlesToday` y la UI muestre el mensaje específico de límite alcanzado.

### 5. La confirmación de "¿regenerar igual?" es lógica de negocio en el usecase, la decisión de mostrar el diálogo es de la UI

Se agrega un método (ej. `GenerateDailySummary.wouldRegenerateWithSameArticles()`) que compara `countTodayArticles()` contra el `articleCount` del `DailySummary` ya guardado para hoy (si existe). `SummariesScreen` llama a este chequeo antes de invocar `generateTodaySummary`; si devuelve `true`, muestra un diálogo de confirmación y solo continúa si el usuario confirma. El widget no decide el criterio de "cambió o no" (eso es negocio, vive en el usecase) — solo decide cuándo mostrar el diálogo según ese resultado.

## Risks / Trade-offs

- **[Riesgo]** El "día" del presupuesto es el día del servidor (UTC), no el día local del usuario — alguien cerca de la medianoche podría ver el reset en un momento distinto al que esperaría por su hora local → **Mitigación**: aceptado a propósito por simplicidad (no se threadea un parámetro de fecha del cliente como se consideró para el idioma en `fix-daily-summary-locale`); el impacto es marginal y ya es el comportamiento de referencias similares (NotebookLM resetea "24 horas después del primer uso", no a medianoche local tampoco).
- **[Riesgo]** Contar palabras por espacios en blanco es una aproximación, no tokens reales de Gemini (que cobra por token, no por palabra) → **Mitigación**: aceptado explícitamente en la exploración previa — 30,000 palabras es un número conservador pensado con margen, no una traducción exacta de costo real en tokens.
- **[Trade-off]** Sin historial de días anteriores (una sola fila por usuario) → si más adelante se quiere mostrar "tu consumo de los últimos 7 días", hay que migrar a una fila por día. Aceptado porque no hay ese caso de uso hoy.

## Migration Plan

Nueva migración de Postgres (tabla + función + RLS), y nueva versión de `summarize-articles` que la consulta antes de invocar a Gemini. Sin datos preexistentes que migrar (tabla nueva, arranca vacía — la primera solicitud de cada usuario crea su fila implícitamente vía `INSERT ... ON CONFLICT` dentro de la función). Rollback: revertir el edge function a la versión anterior (sin el chequeo) deja el presupuesto sin aplicar pero no rompe nada; la tabla nueva puede quedar sin uso sin efectos secundarios.
