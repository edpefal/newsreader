## Context

Ver `proposal.md` - Why para la motivación. Estado actual relevante para el diseño:

- `ai_usage_daily` (migración `20260822000000_add_ai_usage_daily.sql`): fila por `(user_id, day)` con `words_used`, y la función `check_and_record_ai_usage(p_words, p_daily_limit)` (`security definer`, lock de fila, reset por cambio de `day`) que hace el chequeo+incremento atómico. Solo se llama desde `summarize-article/index.ts`.
- El cliente Flutter no sincroniza `ai_usage_daily` hoy (verificado: no hay caller en `CloudSyncClient`). El patrón de sync existente (`sources`, `articles`, `daily_summaries`) es pull vía `CloudSyncClient.fetchChangedSince(table, lastSyncedAt)` hacia Hive.
- `ArticleSummaryState` (sealed, `Equatable`) tiene hoy `Loading | Loaded | Error(AppErrorCode)`. El bottom sheet (`article_summary_bottom_sheet.dart`) hace `switch` exhaustivo sobre ese estado; el caso `Error` renderiza un único bloque genérico rojo para cualquier código.
- El mock visual ya validado por el usuario (artifact) fija: sin indicador con ≥6 restantes, pill neutro "Quedan N hoy" con ≤5, y una superficie neutra propia (no roja) para el límite alcanzado, en light y dark, sin usar `ReevoAccent` (ámbar).

## Goals / Non-Goals

**Goals:**
- Migrar el contador server-side de palabras a resúmenes, preservando el mismo patrón atómico y de reset diario que ya existe.
- Exponer el estado de uso al cliente sin agregar una RPC de lectura nueva (leer la tabla vía RLS, como ya documentaba el comentario de la migración original).
- Distinguir en la UI, con un estado propio, el límite diario alcanzado del artículo-demasiado-largo y de cualquier otro error de generación.

**Non-Goals:**
- No se introduce diferenciación de límite por plan/tier (free vs. premium) — sigue aplicando el mismo límite de 25/día a todo usuario con suscripción activa, igual que hoy.
- No se rediseña el paywall ni el flujo de suscripción.
- No se agrega una acción de "comprar más resúmenes" ni ningún mecanismo de top-up — queda fuera de alcance de este change.

## Decisions

### 1. Reemplazar la columna `words_used` en vez de agregar una columna nueva
`ai_usage_daily` pasa a tener `summaries_used integer not null default 0` en lugar de `words_used`. Se descarta mantener ambas columnas en paralelo: no hay ningún caller que siga necesitando el conteo de palabras una vez que se despliega este change (la única lectora es `summarize-article`, que se actualiza en el mismo change), y mantener las dos columnas obligaría a decidir cuál es la fuente de verdad sin beneficio real.

### 2. `check_and_record_ai_usage` se reemplaza por una función equivalente sobre conteo
Se define `check_and_record_ai_usage(p_daily_limit integer)` (sin el parámetro `p_words`, ya no aplica) que reproduce el mismo lock de fila + reset por cambio de día + chequeo/incremento atómico que la función actual, pero incrementando de a 1 en vez de sumar palabras. Se elige reemplazar la firma existente (no versionar con un nombre nuevo tipo `_v2`) porque solo hay un caller (`summarize-article`) y se actualiza en el mismo change/deploy.

### 3. El techo de longitud por artículo es un chequeo separado, antes del contador diario
En `summarize-article/index.ts`, el flujo pasa a ser: (1) contar palabras del input con `countSingleArticleWords` (ya existe), (2) si supera 8,000 → responder `article_too_long` sin tocar `ai_usage_daily` ni invocar a Gemini, (3) si no, llamar a `check_and_record_ai_usage` como hoy. Se mantiene como un `if` simple en la edge function en vez de meterlo dentro de la función SQL, porque es un chequeo que no depende de estado por usuario (es una constante sobre el input de esta solicitud) y no necesita el lock de fila.

### 4. Exponer el estado de uso al cliente vía sync de tabla, no una RPC de lectura
Se sigue el patrón ya documentado en el comentario de la migración original: el cliente agrega `ai_usage_daily` a la lista de tablas que sincroniza `CloudSyncClient.fetchChangedSince`, apoyándose en la política RLS `ai_usage_daily_select_own` que ya restringe la lectura a la fila del propio usuario. Se descarta crear una RPC de solo lectura porque el patrón de sync ya resuelve exactamente este caso (leer el propio estado) para otras tablas, y evita otro endpoint que mantener.

Con esto, el cliente conoce `summaries_used` para el día en curso (comparando `day` contra la fecha local/servidor) sin depender de que una solicitud de resumen falle primero para enterarse del consumo.

### 5. El indicador de uso es derivado en el Cubit, no un nuevo estado de carga
`ArticleSummaryState` no necesita un estado nuevo para "mostrar el pill" — el pill es un dato adicional (`remainingToday: int?`) que el `ArticleSummaryCubit` calcula a partir de lo sincronizado en Hive y expone junto a cualquiera de los estados existentes (se puede mostrar sobre `Loaded`, o antes de disparar la generación). Lo que sí se agrega como caso nuevo del `switch` es el límite alcanzado, porque ese sí cambia la superficie completa del sheet (ya no es "resumen + posible pill", es un estado exclusivo).

### 6. Nuevo estado del sheet para límite alcanzado, no una variante de `Error`
Se agrega un valor explícito al sealed state (ej. `ArticleSummaryLimitReached`) en vez de seguir usando `ArticleSummaryError(AppErrorCode.aiUsageLimitReached)` con un branch especial dentro del renderer de error. Esto evita que el bloque de error genérico (con su color y semántica de "algo falló, se puede reintentar") tenga que ramificar internamente para un caso que conceptualmente no es un error — mantiene el `switch` del bottom sheet exhaustivo y cada rama con una sola responsabilidad visual. `AppErrorCode.aiUsageLimitReached` deja de usarse para este caso (se reemplaza por el estado dedicado); `article_too_long` sí sigue el camino de `ArticleSummaryError` normal, porque ese caso conserva la semántica de "no se pudo generar, artículo específico" más parecida a los demás errores de generación.

## Risks / Trade-offs

- **[Riesgo] La migración de `words_used` a `summaries_used` es una breaking change de esquema** → Mitigación: no hay backfill significativo que preservar (el consumo es por-día, se resetea diariamente de todos modos); la migración solo necesita coexistir el tiempo del deploy. Desplegar la migración y el deploy de `summarize-article` juntos, sin ventana donde una versión vieja de la función siga escribiendo `words_used` contra el esquema nuevo.
- **[Riesgo] Sincronizar `ai_usage_daily` al cliente agrega una tabla más al ciclo de `fetchChangedSince`** → Mitigación: es el mismo patrón ya usado por 3 tablas existentes, sin lógica nueva de sync; el volumen de datos por fila es mínimo (un entero y una fecha).
- **[Trade-off] El techo de 8,000 palabras es una constante hardcodeada, no configurable por el usuario** → Aceptado: afecta a <0.3% de los artículos reales (dato validado contra producción); no se justifica la complejidad de hacerlo configurable para un caso tan marginal.

## Migration Plan

1. Migración SQL: agregar `summaries_used`, migrar/reemplazar `check_and_record_ai_usage`, eliminar `words_used` (una vez confirmado que no queda ningún caller).
2. Actualizar `summarize-article/index.ts` y `word_count.ts` (chequeo de 8,000 palabras + nueva firma de la función SQL).
3. Desplegar a `reevo` y/o `reevo-dev` según lo que confirme el usuario (ver proposal.md - Impact) antes de cerrar el change.
4. Cliente Flutter: sync de `ai_usage_daily`, nuevo estado del Cubit/sheet, nuevos `AppErrorCode` + traducciones.
5. Sin rollback de datos necesario más allá de revertir la migración (el consumo diario no tiene valor histórico que preservar entre días).

## Open Questions

Ninguna — las decisiones de producto (número exacto, unidad, tratamiento visual) ya se validaron con el usuario en la exploración previa a este change.
