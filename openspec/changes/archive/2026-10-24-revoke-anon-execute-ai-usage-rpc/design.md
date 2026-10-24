## Context

`check_and_record_ai_usage(p_daily_limit integer)` es `SECURITY DEFINER` con `search_path=public`, propiedad de `postgres`. Hoy tiene `EXECUTE` para `anon`, `authenticated`, `postgres` y `service_role` tanto en `reevo-dev` como en `reevo` (consultado con `aclexplode` el 2026-10-23). La migración `20260902000000_replace_ai_word_budget_with_summary_count.sql` hace `revoke all ... from public` y `grant execute ... to authenticated`, pero los permisos por defecto de Supabase en el esquema `public` otorgan `EXECUTE` a `anon` a cada función nueva, y `revoke ... from public` no los quita.

La Edge Function `summarize-article` valida el JWT y llama a la función con `userClient` (clave anon más el JWT del usuario), es decir, como rol `authenticated` (`index.ts`, hacia la línea 288). La función usa `auth.uid()`; sin sesión es nulo y el `insert` en `ai_usage_daily` falla, por lo que hoy una llamada anónima no hace nada útil. En `public` solo hay otra función, `cascade_delete_source_articles`, que es un trigger y no `SECURITY DEFINER`.

## Goals / Non-Goals

**Goals:**
- Que `anon` no pueda ejecutar la función, en dev y en prod, y que el repo refleje ese estado.

**Non-Goals:**
- Quitar `authenticated`: obligaría a rediseñar la Edge Function para llamar con `service_role` y pasar el id de usuario.
- Impedir que un usuario con sesión pase un `p_daily_limit` arbitrario llamando directo: solo afecta a su propio contador y el límite real lo aplica la Edge Function.
- Los otros avisos menores del advisor (`cascade_delete_source_articles`, RLS sin políticas en `feed_items`/`generated_feeds`).

## Decisions

### 1. `revoke ... from anon`, solo sobre esta función

La migración es `revoke execute on function check_and_record_ai_usage(integer) from anon;`. Es idempotente (revocar un permiso que no existe no falla) y no toca a `authenticated`, `postgres` ni `service_role`.

*Alternativa descartada:* `alter default privileges ... revoke execute on functions from anon` para todo el esquema. Cambia los permisos por defecto de futuras funciones y puede afectar a otras que sí necesiten `anon`; hoy no hay más funciones y el cambio es más amplio de lo que se pide.

### 2. Aplicación por `apply_migration`, o a mano si el clasificador de permisos lo bloquea

Las migraciones se aplican con `apply_migration` (no `db push`, por el desajuste de versiones del 16 de septiembre). En esta misma sesión el clasificador de permisos de Claude Code bloqueó un `drop table` por `apply_migration`; un `revoke` es mucho menos destructivo, pero si también se bloquea, el usuario lo ejecuta en el SQL Editor de cada proyecto y el resto se verifica con consultas de lectura.

### 3. Verificación con `has_function_privilege`

Tras aplicar, en cada proyecto: `has_function_privilege('anon', 'public.check_and_record_ai_usage(integer)', 'execute')` debe dar `false` y el mismo con `authenticated` debe dar `true`. Después, el usuario comprueba en dev que el resumen de un artículo sigue funcionando (la Edge Function usa `authenticated`).

## Risks / Trade-offs

- [Quitar el permiso equivocado y romper el resumen de artículos] → Solo se revoca `anon`; la Edge Function corre como `authenticated`. La prueba en dev lo confirma antes de aplicarlo en prod.
- [Un permiso por defecto vuelve a conceder `anon` si se recrea la función con `create or replace` en una migración futura] → `create or replace` conserva los permisos existentes; solo una función nueva los recibiría por defecto. Queda anotado para futuras migraciones.
- [Los permisos del repo y de la base vuelven a divergir] → La migración nueva deja el repo como fuente de la verdad para este permiso.

## Migration Plan

1. Crear la migración en el repo.
2. Aplicarla en `reevo-dev`, verificar los permisos y probar un resumen de artículo.
3. Aplicarla en `reevo` y verificar los permisos.

Rollback: `grant execute on function check_and_record_ai_usage(integer) to anon;`.
