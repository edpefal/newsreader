## Context

`article-summaries` y `enrich-mentions` hoy rechazan incondicionalmente a cualquier usuario sin suscripción activa (`hasActiveEntitlement` check al principio de cada función), igual que `daily-summaries` antes de `add-daily-summary-free-tier` (ya archivado, ver ese design.md para el precedente). A diferencia de ese caso, acá el límite diario de `article-summaries` ya vive en una tabla y RPC parametrizados (`ai_usage_daily` / `check_and_record_ai_usage(p_daily_limit)`), pensados desde el inicio para que el límite pueda variar (hoy siempre se le pasa la constante `AI_DAILY_SUMMARY_LIMIT = 25`). Ver proposal.md para el motivo del cambio.

## Goals / Non-Goals

**Goals:**
- Ofrecer 2 resúmenes de artículo gratis por día (con enriquecimiento de menciones completo) a usuarios sin suscripción activa, reusando la tabla/RPC de `ai-usage-budget` existentes sin migración nueva.
- Mismo patrón de gate pre-paywall en `ReaderScreen` que ya se implementó en `SummariesCubit` para `daily-summaries`: consultar el cupo disponible antes de decidir paywall vs. continuar.

**Non-Goals:**
- No se agrega un indicador de cupo restante visible antes de tocar el botón de resumen (decidido en la exploración) — el indicador de "restantes hoy" que ya existe dentro del bottom sheet (`ArticleSummaryLoaded.remainingToday`) sigue siendo el único lugar donde se ve el número.
- No se agrega un mensaje inline de "cupo agotado" antes del paywall, a diferencia de `daily-summaries` — acá se va directo al paywall.
- No se toca el límite de `daily-summaries` ni su tabla (`daily_summary_free_usage`), son independientes.

## Decisions

**El límite pasa a ser dinámico (`isSubscribed ? 25 : 2`), sobre el mismo contador diario.** Alternativa descartada: un contador separado para el cupo gratis (como sí se hizo para `daily-summaries`). Se descartó porque el período coincide (ambos son "por día de servidor") y la tabla ya soporta un límite variable vía `p_daily_limit` — separar el contador solo agregaría una tabla y una decisión arbitraria de qué pasa si el usuario cambia de estado de suscripción a mitad de día. Compartir el contador resuelve ese caso solo (ver escenario "se suscribe a mitad de día" en la spec): el consumo ya hecho simplemente se descuenta del nuevo límite, sin lógica extra.

**El error de límite alcanzado es el mismo para 2/2 y 25/25 (`ai_usage_limit_reached` → `ArticleSummaryLimitReached`).** No se distingue "sos free y se te acabó" de "sos suscriptor y llegaste a tu tope" porque, a diferencia de `daily-summaries`, acá no hace falta comunicar "volvé mañana o suscribite" con un mensaje especial: el usuario free ya vio el paywall antes de llegar a este estado (ver gate en `ReaderScreen`), así que si de todos modos llega a este estado fue por una condición de carrera (cupo se agotó entre el chequeo del cliente y la llamada al backend), un caso raro que no amerita UX dedicada.

**`enrich-mentions` pierde el chequeo de suscripción sin reemplazarlo por nada (ni por su propio límite).** Alternativa descartada: limitarlo también a N enriquecimientos/día. Se descartó porque no consume Gemini ni tiene costo variable relevante (Google Books/iTunes Search/fetch de Open Graph son gratuitos y ya están cacheados por request), y porque ya está acotado indirectamente por cuántos resúmenes de artículo se generaron (2/día gratis, 25/día con suscripción) — no hay forma de invocar `enrich-mentions` con más volumen que eso sin pasar antes por `article-summaries`.

**`AiUsageRepositoryImpl` gana una dependencia de `SubscriptionStatusProvider`.** Es el mismo patrón que ya tiene `GenerateDailySummary` (que también necesitó saber `isSubscribed` para decidir si tocar el cupo gratis). `AiUsageStatus` como entidad no cambia de forma — sigue siendo `{summariesUsedToday, dailyLimit}` — solo cambia de dónde sale `dailyLimit`.

**`ReaderScreen` gana una dependencia de `AiUsageRepository`.** Necesaria para el chequeo pre-paywall en `_onSummaryPressed`, mismo rol que cumple `SummariesCubit` para `daily-summaries`. Se inyecta donde hoy se construye `ReaderScreen` (la ruta correspondiente en el router).

## Risks / Trade-offs

- **[Riesgo] Condición de carrera: el cliente chequea cupo disponible, pasa el gate, pero para cuando la solicitud llega al backend el cupo ya se agotó (otro dispositivo, u otra solicitud casi simultánea)** → Mitigación: aceptado explícitamente — el backend sigue siendo la fuente de verdad vía `check_and_record_ai_usage` (chequeo-e-incremento atómico), y el peor caso es que el usuario vea el estado neutro `ArticleSummaryLimitReached` dentro del sheet en vez del paywall antes de abrirlo — no rompe nada, ni permite pasarse del límite.
- **[Riesgo] Confundir el límite de 25 (suscriptor) con el de 2 (gratis) en el copy del indicador dentro del sheet, que hoy hardcodea "25"** → Mitigación: el requirement "Indicador de uso restante" se actualiza en este change para referenciar "el límite vigente" en vez de "25" fijo; la implementación debe leer `AiUsageStatus.dailyLimit` (ya dinámico) en vez de la constante directamente.
- **[Riesgo] El string localizado `articleSummaryLimitReachedTitle` tiene "25" hardcodeado en el texto (en/es/fr), no un placeholder** → Mitigación: se convierte a una clave ICU parametrizada (`{limit}`), mismo patrón ya usado en el proyecto para `summaryDetailTitle`; sin esto, un usuario free que llega a 2/2 vería un mensaje diciendo "25", incorrecto y confuso.
