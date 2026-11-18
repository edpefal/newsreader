## Context

`revenuecat-webhook` (change `migrate-to-revenuecat`) extrae `event.app_user_id`, descarta anónimos, no-uuid y usuarios inexistentes, consulta el entitlement `pro` por la API REST y hace upsert. Un evento sin `app_user_id` se ignora con 200. Ver `proposal.md` para el problema.

Según la documentación de RevenueCat, `TRANSFER` trae `transferred_from` y `transferred_to` (listas de strings, siempre presentes) y no documenta los campos de identidad del suscriptor (`app_user_id`, `original_app_user_id`, `aliases`). Se envía una sola vez, para el usuario destino, aunque el evento figure en el historial de ambos. La documentación no trae un ejemplo de payload de `TRANSFER`, así que no se asume nada más sobre su forma.

`sync-entitlement` solo sincroniza al usuario de la sesión. Tras restaurar en la cuenta destino sincroniza al destino; el origen no tiene quién lo sincronice salvo este webhook.

## Goals / Non-Goals

**Goals:**
- Que origen y destino de un traspaso queden con el estado real de RevenueCat en `entitlements`.
- Reutilizar el flujo existente por usuario, sin una segunda lógica de escritura.

**Non-Goals:**
- Impedir el traspaso: es una política de RevenueCat (comportamiento de restauración del proyecto), no del backend.
- Cambiar el cliente o `sync-entitlement`.
- Otros eventos sin `app_user_id` distintos de `TRANSFER`.

## Decisions

### D1. Resolver la lista de usuarios del evento en una función pura
`handler.ts` obtiene los identificadores con una función que devuelve `[app_user_id]` si existe; si no, la unión sin duplicados de `transferred_from` y `transferred_to` cuando son listas de strings; si no, una lista vacía. Con lista vacía responde 200 como hoy. La detección se basa en la presencia de las listas, no solo en `type === "TRANSFER"`, para no depender de un valor de tipo que no se verificó en un payload real.
*Alternativa descartada:* decidir por `type === "TRANSFER"` únicamente: más frágil si RevenueCat cambia el nombre del tipo o añade variantes.

### D2. Procesar cada usuario con el flujo existente
Cada identificador pasa por el mismo camino (filtro de anónimo/no-uuid, existencia en `auth.users`, consulta de estado, upsert). El filtro de anónimos y de existencia es el que hace seguro tratar listas que pueden contener ids de otros entornos o anónimos.

### D3. Intentar todos y responder 500 si alguno falla
Se procesan todos los usuarios aunque uno falle, y si hubo algún fallo se responde 500. El reintento de RevenueCat repite todo, y es idempotente porque cada upsert escribe el estado vigente. Se evita así que el fallo de un usuario deje al otro sin sincronizar hasta el siguiente aviso.
*Alternativa descartada:* cortar al primer error: dejaría desactualizado a un usuario que sí se podía sincronizar.

### D4. Tope de identificadores por evento
Se procesan como máximo 20 identificadores por evento; si llegaran más se ignoran los restantes y se registra un aviso. Un traspaso legítimo involucra uno o muy pocos usuarios, y el tope acota el costo de consultas a la API ante un payload anómalo (el request ya viene autenticado por la cabecera).

## Risks / Trade-offs

- [El payload real de `TRANSFER` difiere de la documentación] → la extracción valida que las listas sean arreglos de strings y, si no, ignora el evento con 200 como hoy; la verificación manual con dos cuentas sandbox confirma el caso real antes de darlo por bueno.
- [El mismo traspaso llega a ambos webhooks (`reevo` y `reevo-dev`)] → cada función ignora a quien no existe en su proyecto, igual que con el resto de eventos.
- [Costo extra de una consulta a RevenueCat por cada usuario del evento] → acotado por D4 y por el bajo volumen.
- [Carrera entre `sync-entitlement` y el webhook sobre el mismo usuario] → ambos escriben el estado vigente leído de RevenueCat, por lo que convergen al mismo valor.
- [Orden de archivado respecto de `migrate-to-revenuecat`] → este change solo agrega un requirement nuevo, así que puede archivarse antes o después sin conflicto de deltas.

## Migration Plan

1. Implementar y probar con tests de Deno (sin tocar la base de datos).
2. Desplegar `revenuecat-webhook` a `reevo-dev`, probar el aviso con credenciales de prueba, y luego a `reevo` con la confirmación del usuario.
3. Verificación manual (a cargo del usuario): con dos cuentas de Reevo y el mismo Apple ID sandbox, traspasar la suscripción pulsando "Restaurar compras" en la segunda, y comprobar que la primera queda con `is_active = false`.

*Rollback:* volver a desplegar la versión anterior de la función; no hay datos que revertir, porque las filas de `entitlements` reflejan siempre el estado de RevenueCat.
