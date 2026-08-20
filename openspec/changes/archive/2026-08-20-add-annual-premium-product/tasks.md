## 1. App Store Connect

- [x] 1.1 Crear el producto de suscripción anual en el subscription group "Reevo Premium" (mismo grupo que el mensual), identificador `com.artlab.reevo.premium.annual`. Creado: ASC subscription id `6802818463`.
- [x] 1.2 Confirmar precio anual con el usuario (~$29.99/año, decisión final pendiente de confirmación) y cargarlo en ASC. Confirmado por el usuario. Cargado vía price point USA `10227` ($29.99) + equalización en los 175 territorios (mismo set que el mensual).
- [x] 1.3 Completar localización en/es-MX (Display Name, Description) igual que el mensual. Hecho: en-US id `e3ace174-fea2-4b5f-bd38-41d2a973f54f`, es-MX id `8c03f162-61fd-4664-809e-c0030cc7a660`.
- [x] 1.4 Subir App Store Review Screenshot del producto (paso que causó bloqueo silencioso la vez pasada con el mensual). Hecho: reutilizada la misma captura que el mensual (pantalla de Resúmenes), `assetDeliveryState: COMPLETE`, 1206x2622. Nota: `fileName=SOURCE` literal causa 500 en el POST inicial — hay que usar un nombre de archivo real (ej. `annual_review_screenshot.png`).
- [x] 1.5 Configurar `subscriptionAvailabilities` por territorio (otro paso que causó bloqueo silencioso la vez pasada — separado de tener el precio cargado). Hecho: `availableInNewTerritories: true` + 175 territorios (mismo set que el mensual).
- [x] 1.6 Confirmar que el `state` del producto pasa a `READY_TO_SUBMIT` antes de seguir. Confirmado.

## 2. Superwall

- [x] 2.1 Crear el producto anual en Superwall (`create_product`), vinculado al entitlement `pro` (`56438`) — mismo entitlement que el mensual, no uno nuevo. Creado: producto id `670775` (`com.artlab.reevo.premium.annual`).
- [x] 2.2 Agregar el producto anual al paywall publicado (`255848`) vía `superwall-editor` (sesión en vivo con pairing code). Hecho: producto agregado como referencia `yearly`. Agregado un selector de plan (dos tarjetas Monthly/Yearly) con `set-product-index` en el tap de cada tarjeta, borde resaltado dinámico según `products.selectedIndex`, y el CTA cambiado de `purchase` con `by-index 0` fijo a `by-selected`. Precio bajo el CTA cambiado a `{{ products.selected.price }} / {{ products.selected.period }}`. Nota: precios en blanco en el preview del editor (mismo comportamiento que ya tenía el mensual antes de este cambio) — no resuelto hasta probar en dispositivo real (tarea 3.1).
- [x] 2.3 Republicar el paywall tocando el botón Publish real de la UI del editor (no vía API cruda). Confirmado por el usuario.
- [x] 2.4 Confirmar con `get_paywall` que `products` incluye ambos planes (mensual y anual). Confirmado: `products` trae `monthly` y `yearly`, documento republicado (`paywall_url` con sha nuevo `c8d502b67153`).

## 3. Verificación

- [x] 3.1 Confirmar visualmente en el paywall (dispositivo real o Web Inspector) que ambas opciones aparecen con su precio correspondiente. Confirmado por el usuario en dispositivo real.
- [x] 3.2 Probar una compra sandbox del plan anual de punta a punta: compra → webhook → `entitlements.is_active = true` → `summarize-articles` deja generar (mismo flujo ya validado para el mensual). Confirmado en prod (2026-08-20): `initial_purchase` con `originalAppUserId` correcto → `superwall-webhook` 200 → `entitlements.is_active=true` (14:01:54) → `summarize-articles` 200 (14:09:04). En el camino se encontraron y resolvieron dos bugs reales no relacionados al plan anual en sí:
  - La tabla `entitlements` **nunca se había desplegado en prod** (solo existía en dev) — la migración `20260810000000_add_entitlements.sql` nunca se aplicó a `avyaxzhdilhufyimrzzb`. Aplicada ahora vía `mcp__supabase__apply_migration`. Esto bloqueaba el gate de suscripción para **cualquier** compra real en prod, no solo el plan anual — bug preexistente del change `gate-daily-summary-behind-superwall-paywall`, nunca detectado porque esa verificación de punta a punta solo se había hecho contra dev.
  - Gotcha de testing en sandbox (no es bug de código): el `originalTransactionId`/`originalAppUserId` de una suscripción sandbox queda fijo al Apple ID sandbox desde la primera compra — cancelar y esperar a que expire no libera la asociación con el usuario viejo (los ciclos de auto-renovación acelerada la mantienen viva). La solución fue usar **Clear Purchase History** en el Apple ID sandbox (Ajustes → Sandbox Account, o App Store Connect → Sandbox → Testers) antes de la compra final.
