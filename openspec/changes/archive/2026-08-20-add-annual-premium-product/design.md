## Context

El plan mensual (`com.artlab.reevo.premium.monthly`) ya está configurado de punta a punta y probado con una compra sandbox real (ver `openspec/changes/archive/2026-08-*-gate-daily-summary-behind-superwall-paywall/`). Ese proceso reveló varios bloqueos no obvios (Acuerdo de Aplicaciones de Pago sin activar, App-Specific Shared Secret faltante en Superwall, screenshot de review y `subscriptionAvailabilities` faltantes en ASC) que ya están resueltos a nivel de cuenta — no deberían repetirse para el anual, pero el checklist de ASC (localización, precio, screenshot, disponibilidad) sí hay que repetirlo por ser un producto nuevo.

## Goals / Non-Goals

**Goals:**
- Dejar el plan anual comprable de punta a punta (ASC + Superwall + paywall), con el mismo nivel de confiabilidad que el mensual.

**Non-Goals:**
- No se rediseña el paywall — solo se agrega el producto anual como segunda opción sobre el diseño existente.
- No se implementa lógica cliente para elegir entre planes — Superwall/StoreKit resuelven la selección en el paywall, la app Flutter no distingue entre planes de ningún modo (ambos otorgan el mismo entitlement `pro`).
- No se define trial para el anual en este change — si se quiere, es una decisión aparte.

## Decisions

**Un solo entitlement (`pro`) para ambos planes, no uno nuevo.**
- Alternativa considerada: entitlement separado para el anual. Se descarta porque ambos planes dan acceso idéntico a las mismas funciones — un entitlement por nivel de acceso (no por plan de facturación) es el patrón que ya usa Superwall y evita tener que actualizar `entitlement.ts`/`entitlement_event.ts` del lado del backend.

**Configurar el anual siguiendo el mismo checklist manual que el mensual, no automatizarlo.**
- El checklist de ASC (localización, precio, screenshot de review, disponibilidad por territorio) no tiene un atajo de API que cubra todos los pasos de una — ya se determinó en el change anterior que faltan endpoints públicos para varias partes de esto (el Acuerdo de Pago y el App-Specific Shared Secret, por ejemplo). Se sigue el mismo proceso manual/asistido que funcionó la vez pasada.

## Risks / Trade-offs

- **[Riesgo] Repetir alguno de los bloqueos silenciosos del mensual** (screenshot faltante, disponibilidad por territorio no configurada) → Mitigación: usar el checklist de `gate-daily-summary-behind-superwall-paywall` sección 8.3 como lista de verificación explícita antes de dar el producto por listo, en vez de asumir que "crear el producto" alcanza.
- **[Riesgo] Precio anual mal calibrado frente al mensual** (¿$29.99/año es el descuento correcto frente a $3.99×12 = $47.88/año?) → Es una decisión de producto del usuario, no algo que este change deba inventar; confirmar el precio final con el usuario antes de cargarlo en ASC.
