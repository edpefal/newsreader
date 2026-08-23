## Context

El `NavigationDrawer` vive en `lib/presentation/app/router.dart`, dentro del widget que arma el `Scaffold` de la navegación principal (bottom/side nav vía `StatefulShellRoute`). Usa el `NavigationDrawer`/`NavigationDrawerDestination` de Material 3 sin personalización propia, así que hereda directo del `ColorScheme` global definido en `lib/presentation/theme/app_theme.dart` (`AppTheme.light`).

Ese theme (la dirección "tinta sobre papel" ya documentada en el propio archivo) define `primary` y `secondary` con el mismo negro (`_ink = 0xFF0A0A0A`) y no sobreescribe `secondaryContainer`/`onSecondaryContainer`. Como el indicador de selección del `NavigationDrawer` en M3 usa `colorScheme.secondaryContainer` por default, termina heredando ese negro — de ahí la pill oscura y sobredimensionada visualmente.

`AppTheme.dark` sigue con `ColorScheme.fromSeed` (Material 3 estándar, sin la identidad "tinta sobre papel") y no se toca en este change — ver comentario existente en el archivo sobre el rediseño siendo explícitamente light-mode.

`AuthClient` (`lib/core/auth/auth_client.dart`) ya expone `currentUserId` como getter simple sobre `_supabase.auth.currentUser` en su implementación (`SupabaseAuthClient`); no expone `email` todavía.

Ver `proposal.md` para la motivación completa de cada punto.

## Goals / Non-Goals

**Goals:**
- El indicador de selección del drawer se ve sutil, no domina la pantalla.
- El contador de no leídos nunca se desborda visualmente, sin importar el conteo real.
- El header del drawer muestra el email de la sesión activa, sin espacio vacío forzado.
- Los cambios de color quedan acotados a `AppTheme.light` — dark mode no se toca.

**Non-Goals:**
- No se agrega selector de avatar/foto de perfil (fuera de scope; la app no maneja avatares hoy).
- No se rediseña la lista completa de destinos del drawer (rutas, orden, badges de otras secciones) más allá de lo puntual descripto acá.
- No se toca `AppTheme.dark`.
- No se persiste el email en Hive ni se sincroniza en ningún lado — se lee en vivo desde la sesión de Supabase Auth cada vez que se necesita.

## Decisions

### 1. `secondaryContainer`/`onSecondaryContainer` explícitos en `ColorScheme.light`, no un `NavigationDrawerThemeData` puntual

Se define `secondaryContainer` reusando el token `_hairline` ya existente en `app_theme.dart` (el mismo tono sutil que ya usan `outline` y `surfaceContainerHighest`), con `onSecondaryContainer: _ink`. Esto resuelve el indicador del drawer y de paso deja `ColorScheme.light` completo y consistente para cualquier otro widget Material 3 que dependa de `secondaryContainer` a futuro (ej. `Chip`, `SegmentedButton`), en vez de dejarlos con el negro heredado que causó este bug.

**Alternativa considerada**: `NavigationDrawerThemeData(indicatorColor: ...)` acotado solo al drawer. Se descarta porque el problema real es que `ColorScheme.light` quedó incompleto (nunca se pensó `secondaryContainer` al definir `primary`/`secondary` en negro) — parchear solo el síntoma en el drawer dejaría el mismo bug latente en cualquier otro widget M3 que use `secondaryContainer`.

### 2. `Badge.count` en vez de `Badge` genérico con `Text('$count')`

`Badge.count(count: count)` ya viene de Flutter y capea automáticamente valores grandes (formato tipo "999+"), sin necesitar lógica propia de formateo ni un tamaño de badge custom.

### 3. Header del drawer: `Container` a medida, no `DrawerHeader`

Se reemplaza `DrawerHeader` (que impone una altura mínima pensada para header con avatar) por un `Container`/`Padding` simple con una `Column` (logo + título, email debajo en `bodySmall`/`onSurfaceVariant`). Sin avatar — decisión ya tomada en la exploración previa, dado que la app no maneja fotos de perfil.

### 4. `currentUserEmail` en `AuthClient`, mismo patrón que `currentUserId`

Getter síncrono (`_supabase.auth.currentUser?.email`) en `SupabaseAuthClient`, agregado a la interfaz `AuthClient`. No se agrega un stream dedicado: el email de una sesión no cambia sin un evento de auth completo (login/logout), que ya dispara un rebuild del árbol vía `authStateChanges` en otro punto de la app (el router reacciona a cambios de sesión); el drawer solo necesita leer el valor actual cuando se construye.

### 5. `indent`/`endIndent` en los `Divider`, valor fijo alineado al padding existente

Mismo padding horizontal que ya usan los `ListTile`/destinos del drawer (para que el separador arranque y termine visualmente alineado con el contenido de arriba/abajo), en vez de un valor arbitrario nuevo.

### 6. Ícono de "Leídos": `Icons.mark_email_read`/`mark_email_read_outlined`

Reemplaza `Icons.archive`/`archive_outlined`. Confirmado que ambos existen en el set de Material Icons ya vendorizado por Flutter.

## Risks / Trade-offs

- **[Riesgo]** Reusar `_hairline` como `secondaryContainer` significa que ese tono (ya usado para `outline`/`surfaceContainerHighest`) ahora también pinta el indicador de selección — si en el futuro se necesita que esos tres roles se vean distintos entre sí, habrá que separar los valores. **Mitigación**: aceptado a propósito por consistencia visual hoy; son roles conceptualmente parecidos (superficies sutiles, no acentos).
- **[Trade-off]** `currentUserEmail` puede ser `null` si por algún motivo la sesión no tiene email asociado (ej. un proveedor de auth que no lo devuelva) — el header del drawer debe manejar ese caso sin romper el layout (ej. no mostrar la segunda línea en vez de mostrar un string vacío o "null").

## Migration Plan

Sin migración de datos ni cambios de backend — es un change puramente de UI/theme del cliente. Se despliega con la próxima build de la app; rollback es simplemente revertir el commit, sin pasos adicionales.
