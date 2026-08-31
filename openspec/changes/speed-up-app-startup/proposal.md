## Why

`lib/main.dart` corre 9 pasos secuenciales con `await` antes de llamar a `runApp()` — abrir 5 boxes de Hive, `Supabase.initialize`, `Superwall.configure` (espera un callback nativo), DI, PostHog, identificar usuario, dos migraciones one-time y `SyncUserData.execute()` (fetch de red). La pantalla de arranque nativa (`flutter_native_splash`, ver change `fix-launch-screen-branding`) se queda visible hasta que termina todo ese bloque, así que con red lenta el usuario puede ver el logo estático varios segundos antes de que aparezca cualquier UI interactiva.

## What Changes

- Usar el patrón `FlutterNativeSplash.preserve()` / `FlutterNativeSplash.remove()` (paquete `flutter_native_splash`, que ya es dependencia del proyecto) para controlar explícitamente cuándo desaparece la splash nativa, en vez de depender del comportamiento por defecto ligado al primer frame.
- Mover `flutter_native_splash` de `dev_dependencies` a `dependencies` en `pubspec.yaml` — `preserve()`/`remove()` son APIs de runtime, no solo de generación de assets en tiempo de build.
- Reordenar `main()` para bloquear antes del primer frame solo lo estrictamente necesario: abrir Hive (en paralelo con `Supabase.initialize` vía `Future.wait`, ya que son independientes), `Superwall.configure` (se mantiene bloqueante — ver design.md, riesgo de `MissingPluginException` ya documentado en el código si `SuperwallSubscriptionStatusProvider` se suscribe a su stream antes de que el nativo lo registre) y la inyección de dependencias mínima para que el Inbox pueda leer datos locales.
- Diferir a después de `runApp()`/primer frame lo que implica I/O de red o no es crítico para pintar la primera pantalla: `initPostHog`, la identificación de usuario ante Superwall/observabilidad, las dos migraciones one-time, y `SyncUserData.execute()`.
- El Inbox (y cualquier pantalla que dependa de `SyncUserData`) debe mostrar los datos locales cacheados en Hive de inmediato y reflejar un estado de "sincronizando" mientras el sync de red corre en background, en vez de esperar bloqueado a que termine — reusando el mecanismo `isSyncingInBackground` que `InboxCubit`/`InboxState` ya soportan.

## Capabilities

### New Capabilities
- `app-startup`: comportamiento del arranque en frío de la app — qué se bloquea antes de la primera UI interactiva, cuándo desaparece la splash nativa, y cómo se comunica el estado de sincronización en background.

### Modified Capabilities
(ninguna — no hay spec existente que describa el flujo de arranque)

## Impact

- `lib/main.dart`: reordenamiento de la secuencia de inicialización; se agrega `FlutterNativeSplash.preserve()`/`remove()`.
- `pubspec.yaml`: `flutter_native_splash` pasa de `dev_dependencies` a `dependencies`.
- `features/inbox/presentation/cubit/inbox_cubit.dart`: se dispara `syncInBackground()` (ya existente) tras el sync diferido, en vez de asumir que `SyncUserData` ya corrió al montarse.
- `features/favorites`, `features/archive`, `features/sources`, `features/summaries`: sus cubits se recargan (`loadX()`) una segunda vez cuando el sync diferido termina.
- No afecta la launch screen nativa en sí (assets/colores) — eso ya quedó resuelto en `fix-launch-screen-branding`; este change es sobre cuánto tiempo se mantiene visible y qué corre mientras tanto.
- No se toca el orden ni el bloqueo de `Superwall.configure` — queda fuera de scope por el riesgo conocido de `MissingPluginException` (ver design.md).
