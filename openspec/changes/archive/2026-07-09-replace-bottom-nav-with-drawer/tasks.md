## 1. Reemplazar NavigationBar por NavigationDrawer

- [x] 1.1 En `_ScaffoldWithNavBar` (`lib/presentation/app/router.dart`), eliminar el `bottomNavigationBar` y agregar un `drawer` con `NavigationDrawer`
- [x] 1.2 El `NavigationDrawer` debe incluir un `DrawerHeader` con el nombre de la app y las cuatro `NavigationDrawerDestination` (Inbox, Favoritos, Leídos, Fuentes) con los mismos íconos actuales
- [x] 1.3 Mantener el badge de conteo de no leídos en la entrada Inbox del drawer, usando el mismo `BlocBuilder<InboxCubit>` actual
- [x] 1.4 En `onDestinationSelected` del drawer, cerrar el drawer (`Navigator.pop`), disparar la recarga del cubit correspondiente y llamar `navigationShell.goBranch(index)` — mismo comportamiento que el `NavigationBar` actual
- [x] 1.5 Verificar que el `DrawerButton` (`≡`) aparece automáticamente en los AppBar de las cuatro screens principales

## 2. Verificación

- [x] 2.1 Correr `flutter analyze` sin warnings
- [x] 2.2 Correr `flutter test` sin fallos
