## Context

Ver `proposal.md`. Estado al 2026-11-24: la 1.11.0 (RevenueCat) está en `READY_FOR_SALE`. En PostHog (14 días, `screen_view`) ninguna sesión de producción viene todavía de la App Store en 1.11.0; hay 2 personas en 1.10.0 con última actividad el 2026-11-20 y ninguna en 1.9.x. `entitlements` en producción no tiene suscriptores reales.

## Goals / Non-Goals

**Goals:** retirar Superwall sin dejar a un cliente viejo pagando sin acceso; dejar el repo y la documentación sin referencias activas.

**Non-Goals:** tocar la tabla `entitlements` o sus migraciones; revertir la 1.11.0; retirar nada de RevenueCat.

## Decisions

### 1. La URL de Apple se mueve ya; el webhook y el campaign esperan
Apple permite una sola URL de notificaciones por app. Al moverla a RevenueCat, Superwall deja de recibir las notificaciones de renovación, cancelación y expiración. Se acepta porque no hay suscriptores reales en Superwall y los 2 usuarios de 1.10.0 son, con alta probabilidad, pruebas del propio dueño. El webhook y el campaign no se tocan todavía: son lo que hace que una compra nueva hecha desde 1.9.x/1.10.x siga registrándose.
*Alternativa descartada:* mover la URL solo al final; mantenería a RevenueCat sin notificaciones de servidor durante un mes sin ninguna ventaja.

### 2. El criterio es actividad real, no una fecha fija
El retiro no se programa por calendario: se decide con una consulta en PostHog el día que se quiera ejecutar. Consulta de referencia, sobre `screen_view` en los últimos 30 días: personas con `$app_version` menor que 1.11.0 y `environment = production`. Se cruza con Sentry. Si hay actividad, se espera otros 30 días desde la última. Esto sigue la regla de `CLAUDE.md` sobre el orden de despliegue: un recurso del servidor que usan clientes ya publicados no se elimina hasta que la versión sin la dependencia esté adoptada.
*Alternativa descartada:* forzar la actualización de la app; sería un cambio de producto fuera de este alcance.

### 3. Orden del retiro
1) Confirmar el criterio y el visto bueno del usuario. 2) Archivar el campaign y los paywalls (a cargo del usuario). 3) Eliminar la función de `reevo-dev` y luego de `reevo`, y borrar el secret. 4) PR con la carpeta, el bloque de `config.toml`, `CLAUDE.md` y `README.md`. 5) Revocar la llave "Superwall" de App Store Connect al final, porque es irreversible y no hay nada que la use después del paso 3. Cada despliegue o borrado en `reevo` se confirma con el usuario antes.

## Risks / Trade-offs

- **[Un usuario 1.9.x/1.10.x vuelve tras el retiro y compra]** → paga y no recibe acceso. Mitigación: el criterio de 30 días, y al retirar se deja la función eliminada sin reemplazo para que el fallo sea visible en el paywall viejo y no silencioso.
- **[Se mueve la URL de Apple y un 1.10.0 compra después]** → su compra inicial llega por el SDK de Superwall, pero sus renovaciones y expiraciones no. Impacto acotado a 2 personas sin suscripción real.
- **[Plazo que nunca llega]** si alguien de 1.10.0 abre la app cada mes. Mitigación: tras 60 días sin cumplirse, se evalúa con el usuario si se retira igualmente.
