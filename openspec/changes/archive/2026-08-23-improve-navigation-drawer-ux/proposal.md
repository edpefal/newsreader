## Why

El `NavigationDrawer` tiene varios problemas visuales que se hicieron evidentes al mirar la app en uso real: el indicador del item seleccionado se ve como una pill negra desproporcionada (hereda el negro de `primary`/`secondary` del theme, sin un `secondaryContainer` propio), el contador de no leídos del Inbox se desborda con números grandes (ej. "1436"), el header solo muestra "Reevo" dejando mucho espacio vacío sin ninguna identificación del usuario logueado, los separadores van de borde a borde, y el ícono de "Leídos" (`archive`) no matchea conceptualmente con el label.

## What Changes

- El indicador del item seleccionado del `NavigationDrawer` pasa a usar un `secondaryContainer` claro (con `onSecondaryContainer` oscuro) en vez de heredar el negro de `primary`/`secondary`, en el `ColorScheme.light` de `AppTheme` (dark mode no se toca, sigue con `ColorScheme.fromSeed`).
- El contador de no leídos del Inbox en el drawer pasa de `Badge(label: Text('$count'))` a `Badge.count(count: count)`, que capea automáticamente números grandes (ej. "999+") en vez de desbordar el badge.
- El `DrawerHeader` (con su altura mínima fija que dejaba mucho espacio en blanco) se reemplaza por un header compacto a medida que muestra el logo/título "Reevo" y, debajo, el email del usuario autenticado en texto secundario. Sin avatar.
- `AuthClient` agrega `String? get currentUserEmail`, implementado en `SupabaseAuthClient` con el mismo patrón que el `currentUserId` ya existente, para que el drawer pueda mostrar el email de la sesión activa.
- Los `Divider` del drawer pasan a tener `indent`/`endIndent` alineado al padding horizontal del contenido, en vez de ir de borde a borde.
- El ícono del item "Leídos" cambia de `Icons.archive`/`Icons.archive_outlined` a `Icons.mark_email_read`/`Icons.mark_email_read_outlined`, más fiel al label.

## Capabilities

### New Capabilities
- `navigation-drawer`: comportamiento visual y estructural del `NavigationDrawer` de la app — estilo del indicador de selección, presentación del contador de no leídos, layout del header, separadores de sección e íconos de cada destino.

### Modified Capabilities
- `user-auth`: se agrega el requisito de que el `NavigationDrawer` muestre el email de la sesión activa junto a las opciones existentes (login, logout).

## Impact

- **Cliente**: `lib/presentation/theme/app_theme.dart` (`ColorScheme.light`), `lib/presentation/app/router.dart` (header, badge, dividers, ícono del `NavigationDrawer`), `lib/core/auth/auth_client.dart` y `lib/core/auth/supabase_auth_client.dart` (nuevo `currentUserEmail`).
- **Sin cambios de backend**: todo el trabajo es de UI/theme del lado del cliente; no hay migraciones ni cambios en Edge Functions.
- **Sin cambios de comportamiento de navegación**: los destinos, rutas y lógica de selección del drawer quedan iguales — el change es puramente visual/estructural.
