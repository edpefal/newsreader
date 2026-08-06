## Why

La app exige login obligatorio (Google/Apple vía Supabase Auth, capability `user-auth`) y va a publicarse en App Store y Google Play para público general. Ambas tiendas exigen que cualquier app que permita crear una cuenta dentro de la app también permita eliminarla desde la app, sin depender de soporte externo. Hoy el `NavigationDrawer` solo ofrece "Cerrar sesión"; no existe ningún camino para borrar la cuenta ni para exportar los datos del usuario. Esto es un bloqueante de compliance para el release, no una mejora incremental.

## What Changes

- **BREAKING** (para la cuenta del usuario, no para la API): el usuario puede eliminar irreversiblemente su cuenta desde el `NavigationDrawer`, con una confirmación explícita que deje claro que la acción no se puede deshacer.
- El borrado de cuenta elimina, del lado del servidor, todas las filas del usuario en `sources`, `articles` (estado de usuario) y `daily_summaries`, e invalida al usuario en Supabase Auth (`auth.users`). Requiere una Edge Function con service role, ya que el cliente no tiene permisos para borrar su propio registro de `auth.users` ni para bypasear RLS y borrar en cascada.
- Tras confirmar el borrado en el servidor, el cliente limpia sus datos locales en Hive (reutilizando la lógica ya existente de `ClearLocalUserData`) y cierra la sesión, volviendo a la pantalla de login.
- El usuario puede exportar sus datos desde el `NavigationDrawer`: como mínimo, sus fuentes suscritas en formato OPML (reutilizando el conocimiento de generación de OPML que ya existe en el flujo de import) y sus artículos favoritos en un archivo JSON.
- La exportación se resuelve en el dispositivo, compartiendo el archivo generado vía el mecanismo nativo de compartir (no requiere backend nuevo si los datos ya están sincronizados localmente).

## Capabilities

### New Capabilities
- `account-deletion`: borrado irreversible de la cuenta del usuario y todos sus datos asociados (servidor + local), disparado desde la app.
- `data-export`: exportación de fuentes (OPML) y favoritos (JSON) del usuario a un archivo compartible, generada localmente.

### Modified Capabilities
(ninguna — ambas son capabilities nuevas; no cambian los requisitos existentes de `user-auth` ni de `cloud-sync`, aunque se apoyan en su infraestructura)

## Impact

- Backend: nueva Edge Function (ej. `delete-account`) con service role key, invocada por el cliente autenticado, que borra en cascada las filas del usuario y luego el usuario de `auth.users`.
- `lib/features/auth/` o un nuevo feature `lib/features/account/`: nuevo use case `DeleteAccount`, UI de confirmación, integración con `ClearLocalUserData` y `AuthClient.signOut()`.
- Nuevo feature o extensión de `sources`/`favorites` para `ExportData`: reutiliza el conocimiento de serialización OPML (`ImportOpml`/parsers existentes, en sentido inverso) y agrega serialización JSON de favoritos.
- `lib/presentation/app/router.dart` y `_ScaffoldWithNavBar`: nuevas entradas en el `NavigationDrawer`.
- Dependencia nueva probable: `share_plus` (o equivalente) para el mecanismo nativo de compartir el archivo exportado — a evaluar en `design.md` contra las abstracciones ya definidas en `core/` (CLAUDE.md exige no importar librerías de terceros fuera de `core/`).
- Tests nuevos: unit tests de `DeleteAccount`/`ExportData`, y de la Edge Function si el proyecto tiene tests de backend.
