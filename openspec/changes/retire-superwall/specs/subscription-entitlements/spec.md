## REMOVED Requirements

### Requirement: Compatibilidad temporal con el webhook de Superwall
**Reason**: `superwall-webhook` se elimina una vez cumplido el criterio de retiro (30 días sin actividad de clientes 1.9.x o 1.10.x en PostHog), así que la compatibilidad temporal deja de existir.
**Migration**: No hay migración para el cliente: la versión 1.11.0 y posteriores usan RevenueCat y `sync-entitlement`/`revenuecat-webhook` para sincronizar `entitlements`.
