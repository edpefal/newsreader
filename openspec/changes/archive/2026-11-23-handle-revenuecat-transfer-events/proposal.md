## Why

Cuando RevenueCat traspasa una suscripción de una cuenta a otra (mismo Apple ID, otra cuenta de Reevo, por ejemplo al pulsar "Restaurar compras" en la segunda cuenta), envía un evento `TRANSFER` que **no trae `app_user_id`**: identifica a los usuarios en `transferred_from` y `transferred_to`, y se manda una sola vez, para el usuario destino. `revenuecat-webhook` ignora con 200 todo evento sin `app_user_id`, así que la cuenta de origen puede quedarse con `is_active = true` en `entitlements` sin tener ya acceso en RevenueCat, y conservaría el presupuesto y los resúmenes premium del servidor.

## What Changes

- `revenuecat-webhook` procesa los eventos `TRANSFER`: toma los identificadores de `transferred_from` y `transferred_to`, y para cada uno aplica el mismo tratamiento que a un evento normal (ignora anónimos y usuarios que no existen en su proyecto, consulta el estado vigente del entitlement `pro` a RevenueCat y hace upsert en `entitlements`).
- Si el traspaso incluye varios usuarios y la sincronización de alguno falla, el webhook responde con un error de servidor para que RevenueCat reintente; el reintento es seguro porque cada escritura refleja el estado vigente, no el contenido del evento.
- Un evento sin `app_user_id` que no es un traspaso sigue ignorándose con 200, igual que hoy.
- No cambia `sync-entitlement`: sincroniza solo al usuario de la sesión, que tras restaurar es el destino. La cuenta de origen la cubre el webhook.
- No hay cambios en el cliente ni en la base de datos.

## Capabilities

### New Capabilities

### Modified Capabilities
- `subscription-entitlements`: se agrega el requirement de traspaso de suscripción entre cuentas (el webhook sincroniza origen y destino). Va como requirement nuevo, no como modificación, porque el requirement del webhook del spec principal lo reemplaza `migrate-to-revenuecat` al archivarse; así los dos changes no se pisan.

## Impact

- **Servidor:** `supabase/functions/revenuecat-webhook/` (handler y tests de Deno). Se despliega a `reevo-dev` y `reevo`. Sin secrets nuevos.
- **Cliente:** ninguno; no hace falta una versión nueva de la app ni afecta a clientes ya publicados.
- **Compatibilidad:** solo agrega comportamiento ante un evento que hoy se ignora. Los demás eventos y las respuestas existentes (401, 200, 500) no cambian.
- **Verificación manual (a cargo del usuario):** traspasar una suscripción sandbox entre dos cuentas y comprobar que la de origen queda inactiva.
