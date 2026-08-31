## Context

`main()` (ver `lib/main.dart`) hoy corre 9 pasos secuenciales con `await` antes de `runApp()`; la splash nativa generada por `flutter_native_splash` (change `fix-launch-screen-branding`) por defecto desaparece recién en el primer frame de Flutter, así que se queda visible todo ese tiempo. Investigación externa (paquete `flutter_native_splash`, Flutter API docs, varios artículos de optimización de arranque en Flutter) confirma dos patrones estándar: (1) controlar manualmente cuándo desaparece la splash con `FlutterNativeSplash.preserve()`/`.remove()`, y (2) bloquear antes del primer frame solo lo mínimo, difiriendo I/O de red y SDKs no críticos a después. Ver proposal.md - Why.

`InboxCubit` ya tiene el mecanismo `isSyncingInBackground` (usado hoy por `syncInBackground()` al volver del background y `_silentFeedRefresh()` tras login) — se reutiliza para el sync diferido del arranque, sin agregar un estado nuevo.

## Goals / Non-Goals

**Goals:**
- La splash nativa desaparece apenas Hive + DI mínima terminan, no cuando termina el sync de red.
- El Inbox pinta datos locales (o el estado vacío) de inmediato; cuando el sync en background termina, se actualiza solo.
- Mantener el spec `article-lifecycle`/`feed-polling` intactos: no cambia qué se sincroniza ni cada cuánto, solo cuándo respecto al primer frame.

**Non-Goals:**
- No se difiere `Superwall.configure` a background — su completion callback registra el event channel nativo que `SuperwallSubscriptionStatusProvider` necesita para suscribirse sin lanzar `MissingPluginException` (riesgo ya documentado en el código actual). Diferirlo requeriría registrar ese provider como singleton async en `get_it` y hacer que cualquier caller de `showPaywall`/`identify` espere su `isReady`, lo cual es un cambio de DI más invasivo — fuera de scope de este change.
- No se cambia el mecanismo de sync en sí (`SyncUserData`, `CloudSyncClient`, cursor de `updated_at`) — solo cuándo se dispara respecto al primer frame.
- No se agrega retry/backoff nuevo para el sync en background; si falla, se comporta igual que hoy (errores ya se capturan vía `TelemetryClient` en rutas similares como `_silentFeedRefresh`).

## Decisions

**`FlutterNativeSplash.preserve()` + `.remove()` en vez de dejar el comportamiento por defecto.**
Es el patrón documentado por el propio paquete (ya usado en el change `fix-launch-screen-branding` solo para generar assets) para desacoplar "cuándo desaparece la splash" de "cuándo se pinta el primer frame". Requiere moverlo de `dev_dependencies` a `dependencies` en `pubspec.yaml`, porque `preserve()`/`remove()` son APIs de runtime (`RendererBinding.deferFirstFrame`/`allowFirstFrame` por debajo), no solo herramientas de build. Alternativa descartada: dejar el comportamiento default — es exactamente el problema que se está resolviendo.

**Reordenar `main()` en dos fases: bloqueante mínima antes de `runApp()`, diferida después.**
Fase bloqueante (necesaria para que el Inbox lea datos locales sin crashear): abrir las 5 boxes de Hive y `Supabase.initialize` en paralelo vía `Future.wait` (son independientes entre sí — ninguno necesita el resultado del otro), luego `Superwall.configure` (ver Non-Goals) y `setupDependencies()`. Recién ahí `runApp()`, seguido de `FlutterNativeSplash.remove()` en un post-frame callback.
Fase diferida (dispara justo después de `runApp()`, sin bloquear): `DefaultTelemetryClient.initPostHog`, identificación de usuario ante Superwall/observabilidad, las dos migraciones one-time (`MigrateArchivedArticles`, `ResetLocalArticles` — son operaciones locales de Hive, pero se difieren igual porque no son necesarias para la primera pintura y evitan sumar latencia al camino crítico), y `SyncUserData.execute()`. Al terminar esta fase, se recargan los cubits: `InboxCubit` vía su `isSyncingInBackground` existente (emitir el flag, correr el sync, recargar), y `FavoritesCubit`/`ArchiveCubit`/`SourcesCubit`/`SummariesCubit` simplemente llamando de nuevo a su `loadX()` respectivo.
Alternativa descartada: paralelizar todo con un `Future.wait` gigante — varios pasos sí dependen entre sí (DI necesita que Hive/Supabase/Superwall ya hayan terminado; la identificación de usuario necesita que DI y PostHog ya existan), así que un `Future.wait` sin distinguir dependencias rompería el orden real.

**Cubits leen datos locales en la fase bloqueante, no esperan al sync diferido.**
`loadArticles()`/`loadFavorites()`/etc. ya leen directo de los datasources locales (Hive), no de `SyncUserData` — no hace falta ningún cambio en esos use cases, solo en el orden de `main()`. Alternativa descartada: que los cubits esperen explícitamente una señal de "sync terminado" antes de su primer `load` — innecesario, porque ya están diseñados para leer caché local primero (mismo patrón que pull-to-refresh).

## Risks / Trade-offs

[Arranque en frío sin caché local (primer login en un dispositivo nuevo) muestra el Inbox vacío por un instante antes de que `SyncUserData` traiga los datos] → Aceptable: es el mismo caso que ya maneja `syncAfterSignIn()` (emite `InboxLoading(isSyncing: true)`) — se reusa esa ruta para el primer arranque post-login, no la ruta silenciosa de `syncInBackground()`.

[Doble parpadeo de splash si `FlutterNativeSplash.remove()` se llama antes de que el widget raíz realmente haya pintado] → Se llama desde un `addPostFrameCallback` registrado dentro de `runApp` (no inmediatamente después de la línea `runApp()`), que garantiza que ya hubo un frame renderizado.

[Diferir `Superwall.configure` habría dado más ahorro, pero se descartó por riesgo de `MissingPluginException`] → Documentado como Non-Goal; si a futuro se quiere perseguir, es un change aparte enfocado en DI async de Superwall.

[Migrar `initPostHog` a diferido significa que los primeros eventos de la sesión (si el usuario interactúa muy rápido) podrían perderse si el usuario cierra la app antes de que termine] → Trade-off aceptado: mismo riesgo que cualquier init diferido de analytics, y el volumen de eventos perdidos en ese instante es marginal frente a la mejora de percepción de arranque.
