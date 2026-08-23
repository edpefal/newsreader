## 1. SettingsScreen

- [x] 1.1 Convertir `SettingsScreen` de `StatelessWidget` a `StatefulWidget`, agregando parámetros de constructor `exportUserData` (`ExportUserData`) y `deleteAccount` (`DeleteAccount`).
- [x] 1.2 Agregar una sección "Cuenta" (nuevo título de sección localizado) debajo de la sección de tema, con un `ListTile` "Exportar mis datos" (`Icons.ios_share`) y un `ListTile` "Eliminar cuenta" (`Icons.delete_forever`, color de error), reproduciendo el estilo que hoy tienen en el drawer.
- [x] 1.3 Portar `_exportUserData`, `_confirmDeleteAccount` y `_deleteAccount` desde `_ScaffoldWithNavBarState` (en `router.dart`) al nuevo `State` de `SettingsScreen`, usando los usecases recibidos por constructor en vez de `getIt<>()`.
- [x] 1.4 Agregar los imports necesarios en `settings_screen.dart`: `DeleteAccountDialog`, `AppException`, `AppErrorCodeLocalizations`.

## 2. router.dart

- [x] 2.1 Actualizar el `GoRoute` de `/settings` para resolver `getIt<ExportUserData>()` y `getIt<DeleteAccount>()` y pasarlos al constructor de `SettingsScreen`.
- [x] 2.2 Eliminar de `_ScaffoldWithNavBarState` los `ListTile` de "Exportar mis datos" y "Eliminar cuenta" del `NavigationDrawer`, dejando el `Divider` seguido de "Configuración" y "Cerrar sesión".
- [x] 2.3 Eliminar `_exportUserData`, `_confirmDeleteAccount` y `_deleteAccount` de `_ScaffoldWithNavBarState`, y los imports que queden sin uso (`DeleteAccountDialog`, `ExportUserData`, `DeleteAccount`, `AppException` si ya no se usan ahí).

## 3. Specs y OpenSpec

- [ ] 3.1 Correr `openspec sync` (o el paso de sync equivalente) para que `openspec/specs/data-export/spec.md` y `openspec/specs/account-deletion/spec.md` reflejen el nuevo punto de entrada tras archivar el change.

## 4. Verificación

- [x] 4.1 Correr `flutter analyze` y confirmar cero warnings.
- [x] 4.2 Correr `flutter test` y confirmar que la suite sigue en verde (ajustar/mover cualquier test que referencie los `ListTile` en el drawer o en Settings si existiera).
- [x] 4.3 Probar manualmente: abrir el drawer y confirmar que ya no aparecen "Exportar mis datos" ni "Eliminar cuenta"; entrar a Configuración y confirmar que ambas acciones funcionan igual que antes (exportar genera y comparte los archivos; eliminar cuenta muestra el diálogo de confirmación y, al confirmar, borra la cuenta).
