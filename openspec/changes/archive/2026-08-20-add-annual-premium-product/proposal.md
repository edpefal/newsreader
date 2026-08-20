## Why

Cuando se configuró Reevo Premium se decidió ofrecer dos planes ($3.99/mes y ~$29.99/año), pero por foco en destrabar el lanzamiento solo se llegó a crear el producto mensual en App Store Connect y Superwall. El anual da un mejor valor a usuarios comprometidos y mejora el LTV, pero no es bloqueante para lanzar — se puede agregar después sin tocar el flujo mensual ya funcionando.

## What Changes

- Nuevo producto de suscripción anual en App Store Connect (`com.artlab.reevo.premium.annual` o identificador equivalente), mismo subscription group ("Reevo Premium") que el mensual, precio ~$29.99/año.
- Nuevo producto importado en Superwall, vinculado al mismo entitlement `pro` (`56438`) que ya usa el mensual — no crea un entitlement nuevo, ambos planes otorgan el mismo acceso.
- Agregar el producto anual como segunda opción en el paywall publicado (`255848`), junto al mensual, vía `superwall-editor`.
- Fuera de alcance: cambiar el diseño del paywall más allá de agregar el selector/opción del segundo producto; cambiar el precio del mensual; ofrecer trial en el anual (a decidir en otro momento si se quiere).

## Capabilities

### New Capabilities
- `annual-subscription-plan`: ofrece un plan anual de Reevo Premium como alternativa al mensual, con el mismo entitlement y acceso.

### Modified Capabilities

(ninguna — no hay capacidad de suscripción documentada previamente en `openspec/specs/`; este change solo agrega, no modifica comportamiento existente)

## Impact

- App Store Connect: nuevo producto de suscripción, localización, precio, disponibilidad por territorio (los mismos pasos que se hicieron para el mensual — ver `openspec/changes/archive/*-gate-daily-summary-behind-superwall-paywall/tasks.md` sección 8.3 como referencia de qué faltó configurar la primera vez, especialmente el App Store Review Screenshot y `subscriptionAvailabilities`, que fueron las causas reales de bloqueos la vez pasada).
- Superwall: nuevo producto (`create_product`, vinculado al entitlement `pro`), agregado al paywall `255848` vía editor en vivo (no vía API cruda — ver memoria `feedback_superwall_publish_via_api_incomplete`, hay que republicar desde el botón real de la UI).
- Sin cambios en el código Flutter — el precio y período del anual se resuelven en runtime igual que el mensual (StoreKit + Liquid en el paywall), no hay lógica cliente que distinga entre planes.
