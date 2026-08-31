## 1. Dependencia y control de la splash

- [x] 1.1 Mover `flutter_native_splash` de `dev_dependencies` a `dependencies` en `pubspec.yaml` y correr `flutter pub get`.
- [x] 1.2 En `main()`, llamar `FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized())` como primera línea.

## 2. Reordenar la fase bloqueante de `main()`

- [x] 2.1 Paralelizar con `Future.wait` la apertura de las 5 boxes de Hive junto con `Supabase.initialize` (son independientes entre sí).
- [x] 2.2 Mantener `Superwall.configure` y `setupDependencies()` como bloqueantes, inmediatamente después (sin cambios de comportamiento, solo de posición relativa a los pasos que se mueven al paso 3).
- [x] 2.3 Llamar a `loadArticles()`/`loadFavorites()`/`loadArchive()`/`loadSources()`/`loadSummaries()` de los cubits en esta fase (leen solo datos locales de Hive, no dependen del sync).
- [x] 2.4 Envolver `runApp(...)` con un `WidgetsBinding.instance.addPostFrameCallback((_) => FlutterNativeSplash.remove())` para remover la splash recién cuando el primer frame ya se pintó.

## 3. Diferir trabajo no crítico a después del primer frame

- [x] 3.1 Crear una función `_runDeferredStartupWork()` (o similar) en `main.dart` que agrupe: `DefaultTelemetryClient.initPostHog`, la identificación de usuario ante Superwall/observabilidad (incluyendo el listener de `authStateChanges`), las dos migraciones one-time (`MigrateArchivedArticles`, `ResetLocalArticles`), y `SyncUserData.execute()`, en ese orden.
- [x] 3.2 Invocar `_runDeferredStartupWork()` sin `await` (`unawaited(...)`) justo después de `runApp(...)`, para que corra en background sin bloquear el primer frame.
- [x] 3.3 Al terminar `SyncUserData.execute()` dentro de `_runDeferredStartupWork()`, disparar `getIt<InboxCubit>().syncInBackground()` en vez de una simple recarga, para reusar el flag `isSyncingInBackground` que la UI ya sabe mostrar.
- [x] 3.4 Recargar `FavoritesCubit`/`ArchiveCubit`/`SourcesCubit`/`SummariesCubit` (llamando de nuevo a su `loadX()`) al terminar el sync diferido.
- [x] 3.5 Capturar y reportar por `TelemetryClient` cualquier excepción de `_runDeferredStartupWork()` (mismo patrón que `_silentFeedRefresh` en `InboxCubit`), para no dejar un `Future` sin manejar ni crashear la app si algo falla en background.

## 4. Caso especial: primer login sin caché local

- [x] 4.1 Confirmar que el flujo de login (`syncAfterSignIn()` en `InboxCubit`, disparado desde el login, no desde `main()`) sigue funcionando igual — no se toca, solo se verifica que no quedó doble-disparado con el nuevo sync diferido del arranque. Verificado: `App._AppState` tiene su propio listener de `authStateChanges` (independiente del que ahora vive en `_runDeferredStartupWork`) que ya disparaba `syncAfterSignIn()` antes de este change; no se introdujo una segunda invocación.

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` — sin warnings nuevos.
- [x] 5.2 Correr `flutter test` — sin regresiones, especialmente en tests existentes de `InboxCubit`/`InboxState`. 525 tests, todos pasan.
- [x] 5.3 Pedirle al usuario que corra la app en dispositivo/simulador con red normal y con red simulada lenta (Network Link Conditioner o similar), y confirme que: (a) la splash desaparece rápido, (b) el Inbox muestra datos locales de inmediato, (c) el indicador de "sincronizando" aparece y desaparece correctamente, (d) no hay parpadeo doble de splash. No automatizar taps ni lanzar `flutter run`, según CLAUDE.md — la prueba manual la hace el usuario. Confirmado por el usuario: funcionó.
