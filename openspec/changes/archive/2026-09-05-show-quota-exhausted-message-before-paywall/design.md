## Context

Hoy `ReaderScreen._onSummaryPressed` (`lib/features/reader/presentation/screens/reader_screen.dart`) resuelve el chequeo de suscripción/cupo gratis *antes* de abrir el bottom sheet: si no hay suscripción y no hay cupo gratis, llama directo a `widget.subscriptionStatusProvider.showPaywall(...)` sin abrir el sheet. El bottom sheet (`showArticleSummarySheet`, `article_summary_bottom_sheet.dart`) siempre arranca su `ArticleSummaryCubit` llamando a `generate(article, language)`, que dispara el use case de generación. `SubscriptionStatusProvider` es una abstracción de `core/subscription/`, así que cualquier feature puede depender de ella directamente (no rompe la regla de "un feature nunca importa de otro feature").

Ver proposal.md - Why, para la motivación.

## Goals / Non-Goals

**Goals:**
- Que el usuario sin suscripción y sin cupo gratis siempre vea el bottom sheet al tocar el botón de resumen, con un estado explicativo en vez del paywall directo.
- Reusar el mismo `SubscriptionStatusProvider.showPaywall` y el mismo flujo post-compra (generación automática) que ya existe, solo moviendo el trigger a un botón dentro del sheet.

**Non-Goals:**
- No se toca `features/summaries` (el resumen diario/semanal desde su propia pantalla) -- usa un patrón de paywall similar pero es una capability y una superficie de UI distintas (pantalla completa, no bottom sheet), y el pedido del usuario es específicamente sobre el botón de resumen de artículo en el lector. Si se quiere el mismo tratamiento ahí, es un change aparte.
- No se cambia el estado neutro `ArticleSummaryLimitReached` existente (rechazo del backend post-intento, con o sin suscripción) ni su copy -- sigue aplicando solo cuando ya se intentó generar y el backend lo rechazó por límite diario.

## Decisions

**Nuevo estado de cubit sin invocar el use case: `ArticleSummaryFreeTierExhausted`.**
En vez de reinterpretar `ArticleSummaryLimitReached` (que ya tiene semántica propia: rechazo del backend, aplica con o sin suscripción, muestra el número real del límite), se agrega un estado nuevo y un método de entrada nuevo en `ArticleSummaryCubit`, `showFreeTierExhausted()`, que emite el estado sin llamar a `GenerateArticleSummary` ni a `AiUsageRepository`. Alternativa descartada: reusar `ArticleSummaryLimitReached` con un flag adicional -- se descarta porque mezclaría dos causas distintas (rechazo del backend vs. chequeo local previo) en un solo estado, complicando el `switch` de la UI y el criterio "mismo estado sin importar 25 o 2" que ya blindan los tests existentes de `ArticleSummaryLimitReached`.

**`showArticleSummarySheet` decide qué arranque del cubit usar, vía un parámetro explícito.**
Se agrega un parámetro `bool openFreeTierExhausted` (default `false`) a `showArticleSummarySheet`. Cuando es `true`, el `create:` del `BlocProvider` llama a `createCubit()..showFreeTierExhausted()` en vez de `..generate(article, language)`. `ReaderScreen._onSummaryPressed` sigue haciendo el mismo chequeo de `isSubscribed`/`freeStatus.limitReached` que ya tenía (no se toca esa lógica), pero en la rama que hoy llama a `showPaywall` directo, ahora llama a `_openSummarySheet(context, openFreeTierExhausted: true)`. Alternativa descartada: una función `showArticleSummaryQuotaExhaustedSheet` separada -- se descarta porque duplicaría el cálculo de `maxHeight` y el resto del setup de `showModalBottomSheet` ya existente.

**El botón de premium dispara el paywall directo desde el widget, con `SubscriptionStatusProvider` inyectado en la firma de `showArticleSummarySheet`.**
`ReaderScreen` ya tiene una instancia de `SubscriptionStatusProvider` (inyectada por constructor, regla del proyecto de inyección por constructor). Se agrega como parámetro requerido a `showArticleSummarySheet` y se threadea a `ArticleSummarySheetContent`, junto con `article` y `language` (que hoy solo vive en el closure del `create:`), para que el botón de premium pueda, al completar la compra, llamar a `context.read<ArticleSummaryCubit>().generate(article, language)` -- mismo patrón "volver a chequear `isSubscribed` en `onSubscribed`" que ya usa `ReaderScreen` y `SummariesCubit`, para no depender solo de que Superwall haya invocado el callback correctamente.

**Copy nuevo, no reusa el de `ArticleSummaryLimitReached`.**
Título/subtítulo propios ("Ya usaste tu resumen gratis de hoy" + CTA a premium) en vez de reusar `articleSummaryLimitReachedTitle`/`Subtitle`, porque ese texto habla de "vuelven mañana a las 00:00" sin mencionar premium, y este estado sí necesita el CTA. Mismo criterio de superficie/tono neutro (no rojo de error) que `_LimitReachedContent`, para consistencia visual dentro del sheet.

## Risks / Trade-offs

- [Riesgo] Un usuario podría interpretar el nuevo botón como una segunda fricción antes de llegar al paywall, en vez de una mejora → Mitigación: es un solo tap adicional, y el mensaje explica por qué aparece, que es justamente el problema que este change resuelve (confusión sobre por qué salió el paywall).
- [Riesgo] Duplicar `article`/`language` como parámetros de `ArticleSummarySheetContent` (ya viven en el closure del cubit) agrega superficie a la firma del widget → Mitigación: es la única forma de disparar `generate` desde un botón fuera del flujo normal del cubit sin acoplar el cubit a `SubscriptionStatusProvider` (que rompería la regla de que el cubit no orquesta paywall, documentada en el comment de `ArticleSummaryCubit`).

## Migration Plan

Sin datos persistidos ni migraciones. Cambio de UI/cubit puro, se libera como cualquier PR normal del flujo del proyecto (rama → PR → CI → merge). Sin rollback especial: revertir el PR restaura el comportamiento anterior (paywall directo).
