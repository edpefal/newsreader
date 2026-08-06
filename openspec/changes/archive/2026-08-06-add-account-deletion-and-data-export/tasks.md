## 1. Backend: borrado de cuenta

- [x] 1.1 Revisar `supabase/migrations/` para confirmar si las FKs de `sources`, `articles` y `daily_summaries` hacia `auth.users` tienen `ON DELETE CASCADE`; si no las tienen, decidir si agregarlas vía nueva migración o borrar esas filas explícitamente en la Edge Function. **Confirmado**: las tres tablas ya tienen `references auth.users(id) on delete cascade` (`20260725000000_sync_user_data.sql`), así que basta con `auth.admin.deleteUser()` — no se necesita borrado explícito de filas.
- [x] 1.2 Crear la Edge Function `delete-account` (`supabase/functions/delete-account/`): valida el JWT del `Authorization` header, extrae `user_id`, y llama a `supabase.auth.admin.deleteUser(user_id)` usando la `service_role` key (el cascade de Postgres se encarga de `sources`/`articles`/`daily_summaries`).
- [x] 1.3 La función responde error claro (sin borrar nada) si el JWT es inválido o falta.
- [ ] 1.4 Tests de la Edge Function: el proyecto no tiene infraestructura de test de backend (confirmado, sin precedente en `supabase/`); se cubre con la verificación manual end-to-end de la tarea 7.3.

## 2. Cliente: caso de uso de borrado de cuenta

- [x] 2.1 Crear `lib/features/account/domain/usecases/delete_account.dart`: invoca la Edge Function `delete-account` con el access token actual; si responde éxito, ejecuta `ClearLocalUserData.execute()` y luego `AuthClient.signOut()`; si falla, propaga el error sin tocar datos locales ni la sesión.
- [x] 2.2 Registrar el use case en `core/di/injection.dart`.
- [x] 2.3 Unit tests de `DeleteAccount`: éxito (verifica orden: borrado remoto → limpieza local → signOut), fallo remoto (no limpia nada), sin sesión activa (no se puede invocar).

## 3. Cliente: UI de borrado de cuenta

- [x] 3.1 Agregar opción "Eliminar cuenta" en `_ScaffoldWithNavBar` (`lib/presentation/app/router.dart`), visualmente diferenciada de "Cerrar sesión" (ícono y texto en `colorScheme.error`).
- [x] 3.2 Mostrar diálogo de confirmación explícito (irreversible, se pierden todos los datos) antes de invocar `DeleteAccount` (`DeleteAccountDialog`).
- [x] 3.3 Mostrar error visible (`SnackBar`) si el borrado falla, sin navegar ni cerrar sesión — `DeleteAccount.execute()` no toca datos locales ni la sesión si la Edge Function no confirma éxito.
- [x] 3.4 Widget test de `DeleteAccountDialog` (confirmar/cancelar). El flujo completo con redirect a `/login` no se cubre con un widget test dedicado: `_ScaffoldWithNavBar` es privado y depende de `StatefulNavigationShell` (no instanciable en tests) y de `getIt`, misma limitación ya documentada para el `AppBar` de búsqueda en el change `add-per-screen-article-search`. Se verifica con la prueba manual end-to-end (7.3).

## 4. Exportación de datos: fuentes (OPML)

- [x] 4.1 Crear `lib/features/account/domain/usecases/export_sources_opml.dart` (o reutilizar lógica de serialización si ya existe algo simétrico al parseo de `ImportOpml`): genera un string OPML válido a partir de `GetSources`.
- [x] 4.2 Unit tests: con fuentes, sin fuentes (OPML válido vacío), caracteres especiales en nombre/URL escapados correctamente.

## 5. Exportación de datos: favoritos (JSON)

- [x] 5.1 Crear `lib/features/account/domain/usecases/export_favorites_json.dart`: genera un JSON a partir de `GetFavorites`, con título, `articleUrl`, `sourceName`, `savedAsFavoriteAt` por artículo.
- [x] 5.2 Unit tests: con favoritos, sin favoritos (lista vacía válida).

## 6. Compartir el archivo exportado

- [x] 6.1 Agregar `share_plus` a `pubspec.yaml`.
- [x] 6.2 Crear la abstracción `FileSharer`/`SharableFile` en `core/sharing/` (nuevo módulo, mismo patrón que `core/network/` o `core/auth/`) con `SharePlusFileSharer` como única implementación, siguiendo la tabla de abstracciones de CLAUDE.md.
- [x] 6.3 Integrar: se agregó `ExportUserData` (`lib/features/account/domain/usecases/export_user_data.dart`) como use case orquestador — genera OPML + JSON y los comparte vía `FileSharer`, evitando poner esa orquestación en el widget/router (regla de "no lógica de negocio en Cubits/widgets").
- [x] 6.4 Agregar opción "Exportar mis datos" en `_ScaffoldWithNavBar`.
- [x] 6.5 Unit test de `ExportUserData` mockeando `FileSharer` (verifica nombre/contenido/mimeType de ambos archivos compartidos). No se agregó un widget test dedicado al `ListTile` del drawer por la misma limitación de `_ScaffoldWithNavBar` documentada en 3.4.

## 7. Verificación final

- [x] 7.1 `flutter analyze` sin warnings nuevos.
- [x] 7.2 `flutter test` completo en verde (301/301).
- [x] 7.3 Prueba manual end-to-end: Edge Function desplegada (`supabase functions deploy delete-account`, ACTIVE en producción) y probada — exportación de fuentes/favoritos, borrado de cuenta con confirmación/cancelación, y caso de error sin conexión, todos exitosos.
