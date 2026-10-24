## Why

`public.check_and_record_ai_usage(integer)`, la función que aplica el límite diario de resúmenes con IA, es `SECURITY DEFINER` y hoy la puede ejecutar el rol `anon` (cualquiera con la clave pública de la app, sin sesión) por `/rest/v1/rpc/`. Es drift entre el repo y la base real: las migraciones hacen `revoke ... from public` y `grant ... to authenticated`, pero Supabase concede `EXECUTE` a `anon` por sus permisos por defecto y ese `revoke` no lo quita. El riesgo es bajo (sin sesión `auth.uid()` es nulo y el insert falla), pero la defensa depende de un detalle interno de la función; el advisor de seguridad de Supabase lo marca y conviene cerrarlo.

## What Changes

- Nueva migración idempotente `revoke execute on function check_and_record_ai_usage(integer) from anon;`, aplicada en `reevo-dev` y `reevo`.
- `authenticated` **conserva** el permiso: la Edge Function `summarize-article` llama a la función con el JWT del usuario, es decir, como `authenticated`. Quitarlo exigiría rediseñar la función con `service_role` y queda fuera de alcance.
- Verificación en ambos proyectos con `has_function_privilege` (`anon` sin permiso, `authenticated` con él) y prueba manual en dev de que el resumen de un artículo sigue funcionando.
- Fuera de alcance: `cascade_delete_source_articles` (es un trigger, no `SECURITY DEFINER`) y las tablas `feed_items`/`generated_feeds` con RLS sin políticas, otros avisos menores del advisor.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `ai-usage-budget`: nuevo requirement que fija que solo un usuario con sesión puede invocar el chequeo e incremento del consumo.

## Impact

- Servidor: una migración en `supabase/migrations/` y su aplicación en los dos proyectos de Supabase. Sin cambios de código en la app ni en las Edge Functions.
- Sin impacto en clientes ya publicados: la app nunca llama a la función directamente, solo la Edge Function con la sesión del usuario, que sigue autorizada.
- Es un `revoke`, así que el rollback es `grant execute on function check_and_record_ai_usage(integer) to anon;`.
