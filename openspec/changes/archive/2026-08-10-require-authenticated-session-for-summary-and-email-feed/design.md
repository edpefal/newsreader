## Context

`delete-account` y `sync-feeds` ya resuelven exactamente este problema: reciben el `Authorization` header, crean un cliente de Supabase con el anon key pero pasando el token recibido, y llaman a `userClient.auth.getUser(token)` — que valida contra el servidor de Auth que el token corresponde a una sesión de usuario real, devolviendo error si es la anon key o cualquier JWT que no sea una sesión válida. `summarize-articles` y `create-feed` no hacen ninguna de estas dos cosas: ni el cliente Flutter manda el token de sesión, ni la función lo valida. Ver proposal.md - Why.

## Goals / Non-Goals

**Goals:**
- Replicar el patrón ya probado (`userClient.auth.getUser(token)`) en las dos funciones que faltan.
- Que el cliente Flutter mande el `accessToken` real, con el mismo patrón que ya usan `DeleteAccount` y `SupabaseFeedSyncTrigger`.

**Non-Goals:**
- No se implementa verificación de pago/entitlement en este change — eso depende de la integración con Superwall y se aborda en un change separado, una vez que exista un `userId` autenticado confiable del que colgar esa verificación (que es justo lo que este change habilita).
- No se cambia el rate-limit existente de `create-feed` (20/hora, global) — queda como una segunda capa de protección, ahora redundante pero no dañina.
- No se separan ambientes dev/prod (change separado).

## Decisions

- **`userClient.auth.getUser(token)` en vez de decodificar el JWT a mano**: es el patrón ya usado en el codebase (`delete-account`, `sync-feeds`), valida contra el servidor de Auth (detecta tokens revocados/expirados, no solo la firma), y evita mantener dos formas distintas de autenticar edge functions.
- **`AuthClient` inyectado en `GeminiSummaryGenerator` y `SupabaseEmailFeedGenerator`** (constructor, como ya se hace en `DeleteAccount`): si `currentAccessToken` es `null`, el generator lanza la excepción existente de ese generator (`SummaryGenerationException` / `EmailFeedGenerationException`) con un mensaje de "se requiere sesión activa", sin llegar a hacer la llamada HTTP — evita un roundtrip innecesario y dexja el mismo camino de manejo de errores que ya usa cada pantalla.
- **401 desde la función, no 403**: es un problema de autenticación (token ausente/inválido/no es de usuario), no de autorización sobre un recurso existente — consistente con lo que ya hacen `delete-account`/`sync-feeds`.

## Risks / Trade-offs

- [Alguna sesión válida pero cuyo `accessToken` esté vencido en el momento exacto del request] → Mitigación: `getUser()` ya maneja esto devolviendo error (no hay tokens "medio vencidos" aceptados); el cliente Flutter ya refresca la sesión automáticamente vía `supabase_flutter`, así que en el flujo normal el token enviado está vigente.
- [Romper compatibilidad con quien hoy llame a estas funciones directamente con la anon key, fuera de la app] → Es exactamente el comportamiento buscado (ver **BREAKING** en proposal.md) — nadie legítimo depende de eso hoy.
