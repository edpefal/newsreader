## 1. Resolución de usuarios del evento

- [x] 1.1 Agregar a `supabase/functions/revenuecat-webhook/` una función pura que devuelva los identificadores de un evento: `[app_user_id]` si existe, la unión sin duplicados de `transferred_from` y `transferred_to` si son arreglos de strings, o vacío en otro caso, con un tope de 20 identificadores, y cubrirla con tests de Deno (usuario simple, traspaso con origen y destino, duplicados, listas que no son arreglos de strings, evento sin ninguno, más de 20)

## 2. Webhook

- [x] 2.1 Cambiar `handler.ts` para procesar cada identificador resuelto con el flujo existente (descartar anónimos y no-uuid, existencia en `auth.users`, consulta de estado, upsert), intentando todos aunque alguno falle
- [x] 2.2 Responder 500 si falló la sincronización de algún usuario, y 200 si todos terminaron o fueron ignorados; mantener el 401 por autorización incorrecta y el 200 para un evento sin usuario identificable
- [x] 2.3 Tests de `handler_test.ts`: origen pasa a inactivo, destino a activo, ambos con un solo aviso, anónimo e inexistente dentro del traspaso se omiten y los demás se sincronizan, falla de uno devuelve 500 pero sincroniza al otro, reintento idempotente, evento sin `app_user_id` ni listas devuelve 200, y traspaso sin autorización devuelve 401
- [x] 2.4 Correr `(cd supabase/functions/revenuecat-webhook && deno test --allow-env)` y `deno fmt` sobre los archivos tocados

## 3. Despliegue y verificación

- [x] 3.1 Desplegar `revenuecat-webhook` a `reevo-dev` y verificar con pruebas de humo (401 sin autorización, 405 con GET)
- [x] 3.2 Confirmar con el usuario y desplegar `revenuecat-webhook` a `reevo`, con las mismas pruebas de humo
- [x] 3.3 Verificación manual (a cargo del usuario): con dos cuentas de Reevo y el mismo Apple ID sandbox, traspasar la suscripción con "Restaurar compras" en la segunda cuenta y comprobar en `entitlements` que la primera queda inactiva y la segunda activa (verificado el 2026-11-23 en producción: la primera cuenta quedó con `is_active=false` y la segunda con `true`, ambas filas actualizadas en el mismo segundo)
- [x] 3.4 Correr `openspec validate handle-revenuecat-transfer-events --strict`
