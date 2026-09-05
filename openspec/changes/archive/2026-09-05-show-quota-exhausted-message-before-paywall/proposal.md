## Why

Hoy, cuando un usuario sin suscripción activa y sin cupo diario gratis (2/día) toca el botón de resumen de un artículo, la app le muestra directo el paywall de Superwall sin abrir el bottom sheet. El usuario no ve ninguna explicación de por qué apareció el paywall en ese momento -- puede parecerle un intento de venta desconectado de su acción, en vez de la consecuencia directa de haber agotado su cupo gratis del día.

## What Changes

- Cuando el usuario sin suscripción activa y sin cupo diario gratis toca el botón de resumen, el sistema ahora abre el bottom sheet (como en cualquier otro caso), mostrando un estado propio que indica que agotó su resumen gratis de hoy, en vez de mostrar el paywall directamente sin contexto.
- Ese estado incluye un botón que, al tocarlo, dispara el paywall de Superwall -- mismo paywall y mismo flujo post-compra (generación automática al completar la compra) que hoy, solo que ahora es una acción explícita del usuario en vez de algo automático.
- Nuevo estado de cubit (`ArticleSummaryFreeTierExhausted`) y nuevo contenido visual en el bottom sheet, distinguible del estado neutro de "límite diario alcanzado" ya existente (`ArticleSummaryLimitReached`, que aplica *después* de intentar generar y ser rechazado por el backend, con o sin suscripción). El nuevo estado aplica *antes* de intentar generar, exclusivamente a usuarios sin suscripción sin cupo gratis, sin llamar al backend.
- Nuevas claves de traducción (inglés, español neutro, francés) para el título, subtítulo y botón de ese estado.

## Capabilities

### Modified Capabilities
- `article-summaries`: cambia el comportamiento de la UI cuando el usuario no tiene suscripción activa ni cupo diario gratis -- en vez de mostrar el paywall directamente, abre el bottom sheet con un mensaje de cupo agotado y un botón explícito para ir al paywall.

## Impact

- `lib/features/reader/presentation/screens/reader_screen.dart` (`_onSummaryPressed`): ya no llama a `showPaywall` directo al detectar `freeStatus.limitReached`; abre el sheet.
- `lib/features/article_summary/presentation/cubit/article_summary_cubit.dart` y `article_summary_state.dart`: nuevo estado y método de entrada que no invoca el use case de generación.
- `lib/features/article_summary/presentation/widgets/article_summary_bottom_sheet.dart`: nuevo contenido visual para el estado, con botón que dispara el paywall (recibe `SubscriptionStatusProvider` o un callback).
- `lib/l10n/app_en.arb`, `app_es.arb`, `app_fr.arb`: nuevas claves.
- Tests existentes de `reader_screen`, `article_summary_cubit` y `article_summary_bottom_sheet` que cubren el caso "sin suscripción y sin cupo gratis".
