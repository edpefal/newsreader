## 1. Theme — indicador de selección

- [x] 1.1 `lib/presentation/theme/app_theme.dart`: en `ColorScheme.light`, definir `secondaryContainer: _hairline` y `onSecondaryContainer: _ink` (reusando el token `_hairline` ya existente en el archivo)

## 2. AuthClient — exponer el email de la sesión

- [x] 2.1 `lib/core/auth/auth_client.dart`: agregar `String? get currentUserEmail` a la interfaz, documentado igual que `currentUserId`
- [x] 2.2 `lib/core/auth/supabase_auth_client.dart`: implementar `currentUserEmail => _supabase.auth.currentUser?.email`

## 3. Drawer — header, badge, dividers e ícono

- [x] 3.1 `lib/presentation/app/router.dart`: reemplazar el `DrawerHeader` actual por un `Container`/`Padding` a medida con el logo/título "Reevo" y, debajo, `getIt<AuthClient>().currentUserEmail` en `bodySmall`/`onSurfaceVariant` (sin mostrar esa segunda línea si el email es `null`)
- [x] 3.2 `lib/presentation/app/router.dart`: reemplazar el `Badge(label: Text('$count'))` del destino "Inbox" (icon y selectedIcon) por `Badge.count(count: count)`
- [x] 3.3 `lib/presentation/app/router.dart`: agregar `indent`/`endIndent` al `Divider` del drawer, alineado al padding horizontal ya usado por los destinos/`ListTile`
- [x] 3.4 `lib/presentation/app/router.dart`: cambiar el ícono del destino "Leídos" de `Icons.archive`/`Icons.archive_outlined` a `Icons.mark_email_read`/`Icons.mark_email_read_outlined`

## 4. Verificación final

- [x] 4.1 Correr `flutter analyze` y resolver cualquier warning
- [x] 4.2 Correr `flutter test` y confirmar que todo pasa (sin regresiones en dark mode, que no se toca) — 415/416 pasan; la única falla (`localized_date_formatter_test.dart`) es preexistente y no relacionada (falla igual en `main` antes de este change)
- [x] 4.3 Probar manualmente en un dispositivo/simulador: abrir el drawer, confirmar que el indicador de selección se ve sutil (no negro), que el header muestra el email de la sesión activa sin espacio vacío de más, que un conteo de no leídos de 4+ dígitos se muestra como "999+" sin desbordar, que los separadores no tocan los bordes, y que "Leídos" usa el nuevo ícono — confirmado en dispositivo real
