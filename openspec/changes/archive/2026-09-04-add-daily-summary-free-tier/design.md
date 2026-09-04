## Context

`summarize-articles/index.ts` hoy chequea `hasActiveEntitlement(entitlementRow)` y devuelve `subscription_required` si no hay suscripción activa, antes de chequear `daily_summary_already_generated` y de invocar a Gemini. `article-summaries` (función separada, `summarize-article/index.ts`) ya resuelve el mismo problema de "cupo server-enforced, cliente refleja el estado" con `check_and_record_ai_usage` (RPC `security definer`, lock de fila + reset por cambio de período + chequeo-e-incremento atómico) sobre la tabla `ai_usage_daily`, sincronizada al cliente vía `AiUsageDailyModel`/`HiveAiUsageDatasource`/`AiUsageRepository`. Ver proposal.md para el motivo del cambio (billing habilitado en Gemini para `reevo` prod).

## Goals / Non-Goals

**Goals:**
- Reusar el patrón exacto de `check_and_record_ai_usage` (tabla + RPC atómica + reset automático) para un segundo contador, semanal, propio de `daily-summaries`, sin tocar la tabla/RPC existente de `article-summaries`.
- El orden de chequeo en `summarize-articles` pasa a ser: suscripción activa → cupo gratis semanal → `daily_summary_already_generated` (sin cambiar el orden de este último respecto a los otros dos ya existentes: sigue después).
- Cliente: extender el mismo patrón cliente-refleja-servidor que ya existe para `AiUsageStatus`, con una entidad/estado paralelo para el cupo semanal.

**Non-Goals:**
- No cambia el límite diario de 25 de `article-summaries` ni su tabla/RPC.
- No cambia el mecanismo de identidad de usuario — se asume que el `user_id` de Supabase Auth que ya usa `check_and_record_ai_usage`/`SyncUserData` es suficiente (confirmado con el usuario durante la exploración previa).
- No define un nuevo mecanismo de sincronización cliente-servidor genérico — el estado del cupo semanal viaja por el mismo `SyncUserData` que ya trae `ai_usage_daily`, agregando el campo nuevo.

## Decisions

**Tabla y RPC nuevas, separadas de `ai_usage_daily`.** Se crea `daily_summary_free_usage (user_id uuid primary key, week_start date, used boolean)` y `check_and_record_daily_summary_free_usage()` (sin parámetro de límite — el límite es fijo en 1, a diferencia de `p_daily_limit` que sí es configurable porque el límite de 25 podía cambiar). `week_start` se calcula server-side como el lunes de la semana ISO en curso (`date_trunc('week', current_date)` en Postgres, que ya usa lunes como inicio). Alternativa descartada: agregar columnas a `ai_usage_daily` y una segunda RPC que las lea — se descartó porque mezclaría dos períodos de reset distintos (diario vs semanal) en la misma fila y complicaría el lock, sin ganar nada (las tablas ya son 1:1 con el usuario en ambos casos).

**`used boolean` en vez de `count integer`.** El límite semanal es fijo en 1 (no hay plan de subir/bajar ese número dinámicamente como sí puede pasar con el límite diario de 25), así que un booleano es más simple y suficientemente expresivo que reusar el patrón de contador entero de `check_and_record_ai_usage`. Si en el futuro el límite semanal necesita ser >1, se migra a `integer` en ese momento — no se sobre-diseña ahora para esa posibilidad.

**Orden de chequeo en `summarize-articles`:** suscripción activa (si activa, salta directo a `daily_summary_already_generated` sin tocar la tabla nueva) → si no hay suscripción, `check_and_record_daily_summary_free_usage()` (si no permite, responde `subscription_required`, mismo código de error que hoy usa la falta de suscripción — el cliente no necesita distinguir "nunca tuvo suscripción" de "tuvo cupo gratis y se le acabó", ambos casos terminan en el mismo paywall) → `daily_summary_already_generated` al final, sin cambios. El RPC de cupo gratis solo se invoca (y por lo tanto solo puede descontar) cuando ya se sabe que no hay suscripción activa, evitando una escritura innecesaria en el camino feliz de un usuario suscripto.

**El descuento del cupo gratis ocurre en el mismo punto que hoy se persiste el `DailySummary` exitosamente, no antes.** A diferencia de `check_and_record_ai_usage` (que chequea-e-incrementa en una sola operación *antes* de invocar a Gemini, aceptando el riesgo de "gastar cupo en una llamada a Gemini que después falla" porque igual son 25 intentos disponibles), acá el cupo es de 1 por semana — gastarlo en un intento que después falla por un error transitorio de Gemini sería mucho más costoso para la experiencia del usuario gratis. Se invierte el orden: primero se llama a Gemini y se persiste el `DailySummary`, y solo si eso tiene éxito se llama a `check_and_record_daily_summary_free_usage()` para descontar. Esto reintroduce (a propósito) la misma ventana de carrera que ya existe hoy para `daily_summary_already_generated` con usuarios gratis concurrentes — aceptable porque el peor caso es "un usuario gratis gasta 2 generaciones en vez de 1 en la misma semana", no un problema de seguridad ni de costo relevante a esta escala.

**Cliente: nueva entidad `DailySummaryFreeUsageStatus` (o campo agregado a un estado compartido), no reutilizar `AiUsageStatus`.** `AiUsageStatus.dailyLimit`/`.remaining` están modelados específicamente para el reset diario de `article-summaries`; forzar el período semanal ahí requeriría un campo condicional o un subtipo. Se prefiere un tipo separado, espejo del existente (`usedThisWeek: bool`, `weekStart: DateTime`), siguiendo el mismo patrón de nombres (`AiUsageRepository` gana un método `getDailySummaryFreeStatus()` o se crea un repositorio hermano — a definir en tasks.md según qué tan grande quede `AiUsageRepository`).

## Risks / Trade-offs

- **[Riesgo] Invertir el orden chequeo/descuento (generar primero, descontar después) abre una ventana donde dos solicitudes concurrentes del mismo usuario gratis podrían ambas generar antes de que la primera descuente** → Mitigación: aceptado explícitamente (ver decisión de arriba) porque el límite de `daily_summary_already_generated` sigue aplicando de forma normal en cualquier caso real (dos taps del mismo botón no producen dos llamadas a Gemini porque la UI deshabilita el botón mientras genera); el escenario solo es alcanzable con llamadas directas a la API fuera de la UI, mismo nivel de riesgo que ya se acepta hoy para `daily_summary_already_generated`.
- **[Riesgo] Confundir al usuario gratis mostrando el mismo error `subscription_required` tanto para "nunca tuvo suscripción" como para "ya gastó su cupo gratis de la semana"** → Mitigación: el cliente ya sabe localmente (vía el estado sincronizado del cupo semanal) cuál de los dos casos es antes de mostrar el paywall, así que puede mostrar el mensaje inline distinto (ver requirement "Indicador de cupo gratis antes de generar") sin depender de que el backend distinga el error — el backend solo necesita rechazar, el cliente decide el copy.

## Open Questions

- Nombre final de la tabla/RPC/campos (`daily_summary_free_usage` es un nombre de trabajo) — no cambia el approach ni las specs, se resuelve al escribir la migración.
