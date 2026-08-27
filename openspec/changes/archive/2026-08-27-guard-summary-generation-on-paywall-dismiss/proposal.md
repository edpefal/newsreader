## Why

Al tocar "Crear resumen" sin suscripción activa, se muestra el paywall de Superwall; si el usuario lo cierra sin comprar, la app igual dispara la generación del resumen. La causa raíz era una configuración remota del paywall (`feature_gating: non_gated` en Superwall, ya corregida a `gated` fuera de este change), pero el código de la app confía ciegamente en que el callback `feature` de `registerPlacement` solo se ejecuta tras una compra exitosa, sin verificarlo. Si esa configuración remota vuelve a cambiar (republicación del paywall, error humano en el dashboard, cambio de SDK), el bug reaparece sin que ningún test lo detecte.

## What Changes

- `SummariesCubit.generateTodaySummary` deja de confiar únicamente en el callback de `showPaywall`/`registerPlacement` para decidir si generar: vuelve a comprobar el estado de suscripción justo antes de invocar la generación, y si sigue sin haber suscripción activa, no dispara ningún proceso (ni siquiera un request al backend).
- El backend (`summarize-articles`) ya rechaza correctamente estas solicitudes sin invocar a la API de IA (ver capability `subscription-entitlements`); este change no lo toca, solo evita que la UI dispare la solicitud innecesaria en primer lugar.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `daily-summaries`: aclara que, tras mostrar el paywall, la generación solo se dispara si el usuario efectivamente completó la compra (suscripción activa verificada de nuevo en ese momento), no simplemente porque el callback de "compra completada" del proveedor de paywall se haya ejecutado.

## Impact

- `lib/features/summaries/presentation/cubit/summaries_cubit.dart`: `generateTodaySummary` re-verifica `_subscriptionStatusProvider.isSubscribed` dentro del callback `onSubscribed` antes de llamar a `_generate`.
- No afecta al backend (`supabase/functions/summarize-articles`), que ya valida la suscripción de forma independiente.
- No afecta la configuración de Superwall (el `feature_gating` del paywall se corrigió directamente vía API como causa raíz, fuera del alcance de este change de código).
