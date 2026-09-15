## Context

`InboxCubit.syncAndReload()` (disparado por el `RefreshIndicator` del Inbox) hoy invoca `FeedSyncTrigger.execute()` (`SupabaseFeedSyncTrigger`, que llama a la Edge Function `sync-feeds`) **una sola vez** por gesto de refresh. `sync-feeds` procesa como máximo `MAX_SOURCES_PER_INVOCATION` (20, constante privada del servidor) fuentes por invocación, ordenadas por `last_synced_at` ascendente (`nullsFirst`) — las menos sincronizadas recientemente primero. Ver `proposal.md` para el problema que esto genera.

La respuesta de `sync-feeds` ya incluye `total` (`results.length`, la cantidad de fuentes que esa invocación efectivamente procesó — igual al tope si el usuario tiene más fuentes que el tope, o al total real si tiene menos), pero el cliente hoy solo parsea `synced` y `failedSourceIds` (`SupabaseFeedSyncTrigger.execute()`); `total` no se usa. Los fallos de fuente individual (`syncSource()` en `sync-feeds/index.ts`) marcan `has_error: true` pero **no** actualizan `last_synced_at` — una fuente que falla queda "atascada" cerca del frente de la cola de prioridad (las menos sincronizadas primero) y puede volver a intentarse en la siguiente invocación dentro del mismo gesto.

`GetSources.execute()` ya existe como use case (usado por `InboxCubit._reload()`) y devuelve la lista de fuentes del usuario ya sincronizada localmente vía `SyncUserData` — es la fuente de verdad más barata que tiene el cliente para saber "cuántas fuentes tiene este usuario en total", sin depender de conocer el valor interno del tope del servidor.

## Goals / Non-Goals

**Goals:**
- Un solo gesto de pull-to-refresh cubre todas las fuentes del usuario cuando es razonablemente posible, sin que el usuario tenga que repetirlo manualmente.
- El mecanismo no depende de conocer el valor exacto de `MAX_SOURCES_PER_INVOCATION` del lado del cliente (evita que un cambio futuro de ese tope en el servidor rompa silenciosamente la lógica del cliente).
- Ninguna fuente se re-consulta innecesariamente cuando una sola invocación ya alcanzó para cubrir todas (evitar carga redundante contra los feeds de origen).
- El tiempo total del gesto queda acotado, incluso en el caso patológico de una cuenta con muchísimas fuentes o con fuentes que fallan de forma persistente.

**Non-Goals:**
- No se modifica `sync-feeds` ni su tope de fuentes por invocación (ver `proposal.md`).
- No se garantiza matemáticamente que el 100% de las fuentes queden cubiertas en un único gesto para cualquier cantidad de fuentes — se acota con un tope de vueltas explícito (ver Decisión 3); superado ese tope, el comportamiento vigente hoy (repetir el gesto) se mantiene como fallback.
- No se resuelve la deduplicación de `failedSourceIds` repetidos entre vueltas de forma perfecta a nivel de identificación de causa — solo se garantiza que el conteo mostrado al usuario no cuente la misma fuente dos veces.

## Decisions

### Decisión 1: El loop vive en `InboxCubit.syncAndReload()`, no en `FeedSyncTrigger`/`SupabaseFeedSyncTrigger`
`FeedSyncTrigger.execute()` sigue representando "una invocación" de `sync-feeds`, tal cual hoy. `InboxCubit.syncAndReload()` es quien decide cuántas veces invocarlo y cuándo detenerse, porque es quien tiene acceso a `GetSources` (necesario para saber el total de fuentes del usuario) y quien ya es responsable de la orquestación completa del pull-to-refresh (subir estado local, disparar fetch, bajar cambios, recargar).

**Alternativa descartada**: mover el loop dentro de `SupabaseFeedSyncTrigger`. Se descarta porque esa clase no tiene acceso a `GetSources` sin romper la regla de abstracciones del proyecto (no debería depender de un use case de otro layer), y porque `FeedSyncTrigger` es una abstracción de infraestructura (una sola llamada HTTP) — mezclar la política de reintento ahí la volvería más difícl de razonar y testear de forma aislada.

### Decisión 2: Condición de parada — comparar el total acumulado de fuentes intentadas contra `GetSources().length`, sin tocar `sync-feeds`
Antes de arrancar el loop, `syncAndReload()` obtiene `sourceCount = (await _getSources.execute()).length` (ya se llama a `_syncUserData.execute()` justo antes en el flujo existente, así que la lista local está al día). En cada vuelta, se suma `result.synced + result.failedSourceIds.length` (fuentes efectivamente intentadas en esa invocación — derivable de campos que `FeedSyncResult` ya expone, sin necesitar el campo `total` de la respuesta cruda) a un acumulador `attemptedTotal`. El loop se detiene en la primera vuelta donde:
- `attemptedTotal >= sourceCount` (ya se intentó, en conjunto, al menos tantas fuentes como tiene el usuario), o
- la vuelta actual intentó 0 fuentes (nada que hacer — usuario sin sesión, o sin fuentes), o
- la vuelta actual devolvió `isNetworkError: true` (sin red; seguir intentando no tiene sentido), o
- se alcanzó el tope de vueltas (ver Decisión 3).

**Por qué no comparar contra el `total` crudo de la respuesta ni contra una constante tipo `MAX_SOURCES_PER_INVOCATION` hardcodeada en el cliente**: acoplaría al cliente a un detalle de implementación del servidor que ya cambió de valor una vez en el historial de este proyecto (ver `centralize-feed-fetching`, donde `CONCURRENCY` pasó de 1 a 3) y podría volver a cambiar. Comparar contra `GetSources().length` es estable frente a ese tipo de ajuste server-side.

**Riesgo aceptado**: como las fuentes que fallan no avanzan su `last_synced_at`, pueden volver a ser tomadas en una vuelta posterior dentro del mismo loop, inflando `attemptedTotal` con la misma fuente contada más de una vez. En el caso extremo (más fuentes con fallo persistente que el tope de fuentes por invocación, todas ellas ordenadas antes que las fuentes sanas en la cola de prioridad), esto podría hacer que el loop se dé por terminado sin haber llegado a intentar alguna fuente sana. Se considera un caso de borde poco realista para el uso típico de la app (pocas fuentes rotas de forma permanente, ver snackbar de "fuentes fallidas" que ya visibiliza el problema) y, de ocurrir, el próximo pull-to-refresh sigue funcionando como red de seguridad — mismo comportamiento que existe hoy sin este cambio.

### Decisión 3: Tope explícito de vueltas y de tiempo total, ambos en el cliente
Se agrega una constante `_maxSyncRounds = 5` y un presupuesto de tiempo total `_maxSyncDuration = Duration(seconds: 60)` en `InboxCubit`. El loop se detiene al llegar a cualquiera de los dos límites, lo que ocurra primero (respetando siempre terminar la invocación en curso, nunca cortándola a mitad de camino). Con el tope de fuentes por invocación actual (20) y la evidencia de producción citada en `centralize-feed-fetching/design.md` (~45-89 fuentes entre cuentas reales), 5 vueltas cubren cómodamente los casos observados hasta ahora sin arriesgar un gesto de refresh que tarde varios minutos.

**Alternativa descartada**: solo tope de vueltas, sin presupuesto de tiempo. Se descarta porque cada invocación individual a `sync-feeds` ya tiene un timeout HTTP de 90s (`SupabaseFeedSyncTrigger._syncFeedsTimeout`) — 5 vueltas en el peor caso (todas al límite del timeout) sumarían 7.5 minutos, un tiempo inaceptable para un gesto de pull-to-refresh. El presupuesto de tiempo acota ese peor caso sin necesitar bajar el tope de vueltas para el caso común (rápido).

### Decisión 4: Agregación de resultados entre vueltas para el feedback final al usuario
`syncAndReload()` devuelve un único `FeedSyncResult` agregado al final del loop (no uno por vuelta): `synced` es la suma de `synced` de cada vuelta; `failedSourceIds` es la unión (deduplicada vía `Set`) de los `failedSourceIds` de todas las vueltas — necesario porque una fuente rota puede aparecer en más de una vuelta (ver Decisión 2); `isNetworkError` es `true` si la vuelta que cortó el loop lo fue. `InboxScreen._onRefresh()` no cambia: sigue mostrando un solo snackbar al final, ahora reflejando el resultado de todo el loop en vez de una sola invocación.

## Risks / Trade-offs

- **[Riesgo] Fuentes con fallo persistente pueden re-intentarse varias veces dentro del mismo gesto** (ver Decisión 2) → Mitigación: acotado por el tope de vueltas/tiempo (Decisión 3); el snackbar de "fuentes fallidas" ya existe y sigue visibilizando el problema real (la fuente está rota), independientemente de cuántas vueltas la reintentaron.
- **[Riesgo] Un gesto de refresh puede tardar más que hoy** (hasta 5 vueltas en vez de 1) para cuentas con muchas fuentes → Mitigación: es el trade-off explícito de esta propuesta (ver `proposal.md` - Why): tardar más en un solo gesto es preferible a que el usuario tenga que repetir el gesto manualmente sin saber por qué. Acotado por el presupuesto de tiempo de la Decisión 3.
- **[Trade-off] El mecanismo de parada (Decisión 2) no es matemáticamente exacto** (puede sobre-contar por fuentes repetidas) → Aceptado: prioriza no depender de un detalle interno del servidor sobre la precisión exacta del conteo; el caso de fallo (terminar antes de tiempo) converge de todas formas en el próximo pull-to-refresh, igual que el comportamiento actual sin este cambio.
