## 1. Migración

- [x] 1.1 Crear `supabase/migrations/20261023000000_revoke_anon_execute_check_and_record_ai_usage.sql` con `revoke execute on function check_and_record_ai_usage(integer) from anon;` y un comentario que explique el drift de permisos por defecto de Supabase y que `authenticated` se conserva porque `summarize-article` llama con el JWT del usuario

## 2. Desarrollo (`reevo-dev`)

- [x] 2.1 Confirmar con el usuario a cuál(es) proyecto(s) aplicar y aplicar la migración en `reevo-dev` con `apply_migration` (o a mano en el SQL Editor si el clasificador de permisos lo bloquea). Aplicada en `reevo-dev` el 2026-10-23 con `apply_migration`, sin bloqueo
- [x] 2.2 Verificar con `has_function_privilege` que `anon` ya no puede ejecutar la función y `authenticated` sí. Verificado en `reevo-dev`: `anon` false, `authenticated` true, `service_role` true
- [x] 2.3 Prueba manual del usuario en dev: pedir el resumen de un artículo y comprobar que sigue funcionando y consumiendo el límite. 2026-10-23: dos intentos fallaron por Gemini (timeout y luego `503 UNAVAILABLE: high demand`), no por el cambio; el log de `summarize-article` muestra que la función superó `check_and_record_ai_usage` como `authenticated` y llegó a llamar a Gemini, y una simulación con el rol `authenticated` en dev (con rollback) devolvió `allowed=true`. Dado por verificado con esa evidencia por decisión del usuario, sin esperar a un resumen completo

## 3. Producción (`reevo`)

- [x] 3.1 Aplicar la migración en `reevo` con confirmación del usuario
- [x] 3.2 Verificar con `has_function_privilege` en `reevo` que `anon` no puede ejecutarla y `authenticated` sí, y que el advisor de seguridad ya no marca la función como ejecutable por `anon`. Aplicada y verificada en `reevo` el 2026-10-24: `anon` false, `authenticated` true, `service_role` true. El advisor ya no lista el aviso de `anon`; queda el de `authenticated` (WARN `authenticated_security_definer_function_executable`), intencional porque la Edge Function llama con el JWT del usuario

## 4. Cierre

- [x] 4.1 Abrir PR contra `main` con la migración, esperar `analyze-and-test` en verde y mergear; archivar el change (`openspec archive revoke-anon-execute-ai-usage-rpc --yes`) en el mismo PR final y borrar la rama
- [x] 4.2 Borrar la nota de memoria `project-ai-usage-rpc-anon-execute` y su entrada del índice, ya cumplida
