## Why

La migración a RevenueCat (`migrate-to-revenuecat`, archivado) salió en la 1.11.0, publicada el 2026-11-24. Superwall quedó vivo a propósito para los clientes 1.9.x y 1.10.x, que todavía compran por su paywall: el webhook `superwall-webhook`, el campaign, la URL de notificaciones de Apple y la llave de App Store Connect. Mientras sigan ahí hay una segunda fuente de verdad de suscripciones, secretos que mantener y documentación contradictoria. Este change cierra esa herencia sin romper a quien aún no actualizó.

## What Changes

- Mover la URL de notificaciones del servidor de Apple a RevenueCat (producción y sandbox). Se puede hacer ya, porque la 1.11.0 está publicada y no hay suscriptores reales en Superwall.
- Esperar el criterio de retiro: **30 días sin actividad de ningún cliente 1.9.x o 1.10.x en PostHog**, con sesión iniciada. La última actividad observada de 1.10.0 fue el 2026-11-20 (2 personas), así que la fecha más temprana es el **2026-12-20**.
- Cumplido el criterio: archivar el campaign y los paywalls de Superwall, eliminar `superwall-webhook` de `reevo-dev` y `reevo`, borrar su secret, quitar su carpeta y su bloque de `supabase/config.toml`, y revocar la llave "Superwall" de App Store Connect.
- Actualizar `CLAUDE.md` (tabla de Edge Functions y párrafo de orden de despliegue) y `README.md`, que todavía dice que el paywall es de Superwall.
- **BREAKING** para clientes 1.9.x y 1.10.x: tras el retiro, una compra hecha por el paywall de Superwall ya no actualizará `entitlements`. Por eso el retiro espera al criterio y no se adelanta.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `subscription-entitlements`: se elimina el requirement "Compatibilidad temporal con el webhook de Superwall", que existía solo hasta este retiro.

## Impact

- `supabase/functions/superwall-webhook/` y su bloque en `supabase/config.toml` (eliminación), el secret `SUPERWALL_WEBHOOK_SECRET` en `reevo` y `reevo-dev`, `CLAUDE.md`, `README.md`.
- Servicios externos: App Store Connect (URL de notificaciones y llave de API), Superwall (campaign y paywalls) y RevenueCat (recibe las notificaciones).
- La tabla `entitlements` y sus migraciones **no cambian**: la usa RevenueCat. Los comentarios históricos de la migración `20260810000000_add_entitlements.sql` se dejan como están.
