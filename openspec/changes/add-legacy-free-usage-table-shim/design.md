## Context

Ver `proposal.md` (Why) para el síntoma y la cronología. Estado actual relevante:

- La tabla `daily_summary_free_usage` y las funciones `check_and_record_daily_summary_free_usage()` y `get_daily_summary_free_usage_status()` se eliminaron en prod y en dev (migración `20260916030000`, aplicada el 2 de octubre). Su definición original está en `20260903010000_add_daily_summary_free_usage.sql`.
- El cliente `1.8.0` build 18 (commit `d93b7b8`) sincroniza esa tabla como **último** paso de `SyncUserData`: `fetchChangedSince('daily_summary_free_usage', cursor)` → filtra por `updated_at > cursor`, ordena por `updated_at` y pagina; por cada fila lee `week_start` y `used`. **Nunca la escribe**; la única escritura la hacía la función `security definer` que ya no existe.
- Como el cursor solo se escribe al terminar el ciclo completo, un error en ese último paso repite todo el ciclo y vuelve a fallar. `syncAfterSignIn()` de ese build espera la sincronización sin `try/catch`, así que el error deja el Inbox en `InboxLoading(isSyncing: true)`.
- El cliente actual (`1.9.0`+) ya no tiene ese paso: no consulta la tabla.
- Estado de la nube en prod hoy: 4 cuentas; la afectada por el error (alta del 6 de octubre) no tiene fuentes. Dev no tiene instalaciones de la `1.8.x`.

## Goals / Non-Goals

**Goals:**
- Que la sincronización y el inicio de sesión de la `1.8.x` completen sin error, con el menor cambio posible en el servidor.
- Que la compatibilidad sea claramente temporal, con un criterio de retiro medible.

**Non-Goals:**
- Restaurar la generación manual de resumen diario en la `1.8.x` (el flujo ya no existe y no se recrea).
- Cambiar el cliente actual o publicar una versión nueva.
- Aplicar nada en dev.

## Decisions

**1. Tabla vacía con el esquema original, no una vista ni la migración de vuelta completa.**
Se recrea `daily_summary_free_usage` con las mismas columnas (`user_id uuid primary key references auth.users on delete cascade`, `week_start date not null default date_trunc('week', current_date)::date`, `used boolean not null default false`, `updated_at timestamptz not null default now()`), RLS activo y la política `daily_summary_free_usage_select_own` (`for select using (user_id = auth.uid())`). El cliente viejo solo lee, y una tabla vacía con ese contrato devuelve `[]` a cualquier consulta con filtro y orden por `updated_at`.
- *Alternativa descartada — una vista vacía con el mismo nombre:* ocuparía menos, pero depende de cómo PostgREST y RLS tratan las vistas (políticas de la tabla subyacente, `security_invoker`, avisos de seguridad de Supabase) y es menos predecible que reproducir exactamente el recurso que el cliente ya conoce.
- *Alternativa descartada — revertir la migración de borrado completa (tabla y funciones):* revive las funciones `security definer` de un flujo que ya no existe, sin nadie que las llame, y amplía la superficie sin ningún beneficio para el cliente viejo (que solo lee).
- *Alternativa descartada — esperar a que actualicen:* los usuarios nuevos que instalen desde una ficha en caché o una descarga previa quedan atascados en el login; es justo el caso que ya ocurrió.

**2. Endurecer los permisos de escritura, aunque la política ya los bloquea.**
Además de no crear políticas de `insert`/`update`/`delete` (con RLS activo eso ya las rechaza), se revocan esos privilegios a `anon` y `authenticated`. Es defensa en profundidad: una tabla de compatibilidad no debe poder poblarse ni por un cambio accidental de políticas.

**3. Solo en prod.**
Dev no tiene instalaciones `1.8.x`, así que aplicarlo allí solo añade una tabla sin uso. La migración queda en el repo y, si algún día se empuja a dev, es inocua. Antes de prod, el SQL se verifica en dev dentro de una transacción que siempre se revierte (ver Migration Plan).

**4. Aplicar con `apply_migration`, no con `db push`.**
Las migraciones del 16 de septiembre figuran en Supabase con otro número de versión que en el repo (`20260917131733` frente a `20260916000000`). `supabase db push` las vería como pendientes e intentaría reaplicarlas. Es un desajuste preexistente que este change no corrige.

**5. Criterio de retiro medible.**
Se documenta en la propia migración y en el spec: retirar la tabla cuando PostHog (eventos `screen_view`, propiedad `$app_version`) no muestre ningún usuario con sesión iniciada en `1.8.x` durante 14 días consecutivos y Sentry no registre `PGRST205` nuevos sobre esa tabla en ese periodo. Se evalúa con una consulta concreta, que queda anotada en las tareas, para que el retiro no dependa de la memoria de nadie.
- *Alternativa descartada — retiro por fecha fija:* depende de la adopción real; una fecha arbitraria repetiría el error de origen (retirar antes de que la versión nueva esté adoptada).

**6. El cliente actual no cambia.**
Se añade un test que fija que `SyncUserData` no consulta `daily_summary_free_usage`, para que nadie la reintroduzca en el cliente sin darse cuenta de que depende de esta compatibilidad.

## Risks / Trade-offs

- [Deshace parcialmente la limpieza del 2 de octubre] → Queda documentado como excepción temporal en el comentario de la migración, en el spec y en las tareas, con criterio de retiro.
- [Hay usuarios en la `1.8.x` con sesión que no aparecen en PostHog (analítica desactivada o sin identificar)] → El criterio de retiro usa también Sentry; el riesgo residual es retirar la tabla con un usuario invisible, que volvería a ver el error. Mitigación: la espera de 14 días y verificar Sentry tras el retiro, con la tabla recreable en minutos.
- [La generación manual en la `1.8.x` sigue rota] → Aceptado y dicho explícitamente; no hay forma barata de soportarla sin reintroducir el flujo.
- [Un usuario ya atascado en el spinner no se recupera hasta que reabra o recargue la app] → Con la tabla de vuelta, su siguiente sincronización completa; basta con reabrir. No hay nada que hacer del lado del servidor para sacarlo de ese estado de forma remota.
- [Se olvida retirar la tabla] → Tarea explícita de retiro con consulta registrada, y recordatorio en el cierre del change.

## Migration Plan

1. Escribir la migración (`CREATE TABLE`, RLS, política de lectura, revocación de escrituras, comentario de excepción temporal con el criterio de retiro).
2. Verificarla en `reevo-dev` con un bloque `DO` que ejecuta el SQL exacto, simula a un usuario autenticado (`set local role authenticated` con `request.jwt.claim.sub`), comprueba que una consulta como la del cliente (filtro y orden por `updated_at`) devuelve vacío sin error, que insertar, actualizar y borrar fallan, y termina con una excepción para revertir todo.
3. Confirmar con el usuario el proyecto (propuesto: solo `reevo` prod) antes de aplicar.
4. Aplicar en prod con `apply_migration`. Verificar: la tabla existe, RLS activo con la política, 0 filas, y la misma consulta del cliente devuelve vacío.
5. Monitorear Sentry: `REEVO-PROD-A/B/G` sin eventos nuevos tras la siguiente sincronización de los usuarios afectados; solo entonces marcarlos como resueltos.
6. Registrar el criterio de retiro y, cuando se cumpla, retirar la tabla con una migración (`drop table`) y cerrar el change.
7. Rollback: `drop table daily_summary_free_usage` devuelve el estado anterior (vuelve a fallar la `1.8.x`).
