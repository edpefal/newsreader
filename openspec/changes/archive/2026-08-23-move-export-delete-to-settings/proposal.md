## Why

"Exportar mis datos" y "Eliminar cuenta" son acciones poco frecuentes de administración de cuenta, pero hoy viven en el `NavigationDrawer`, mezcladas con la navegación principal de la app. La pantalla de Settings ya es el lugar natural para acciones de cuenta y configuración; consolidar ahí reduce el ruido del drawer (que debería limitarse a navegación) y agrupa toda la gestión de la cuenta en un solo lugar.

## What Changes

- Se elimina del `NavigationDrawer` el `ListTile` de "Exportar mis datos" y el de "Eliminar cuenta" (con su ícono en rojo).
- Se agrega a `SettingsScreen` una nueva sección "Cuenta" con dos entradas: "Exportar mis datos" y "Eliminar cuenta", reutilizando la lógica existente (`ExportUserData`, `DeleteAccount`, `DeleteAccountDialog`) que hoy vive en `router.dart`.
- El drawer conserva "Configuración" (que navega a `/settings`) y "Cerrar sesión" tal como están.
- Sin cambios de comportamiento en la lógica de exportación ni de borrado de cuenta: mismos usecases, mismo diálogo de confirmación, mismo manejo de errores.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `data-export`: el punto de entrada para "Exportar mis datos" pasa de estar en el `NavigationDrawer` a estar en la pantalla de Settings.
- `account-deletion`: el punto de entrada para "Eliminar cuenta" pasa de estar en el `NavigationDrawer` a estar en la pantalla de Settings.

## Impact

- `lib/presentation/app/router.dart`: se remueven los `ListTile` de exportar datos y eliminar cuenta, y los métodos privados `_exportUserData`, `_confirmDeleteAccount`, `_deleteAccount` que hoy viven en `_ScaffoldWithNavBarState`.
- `lib/features/settings/presentation/screens/settings_screen.dart`: se agrega una nueva sección de Cuenta con las dos acciones movidas.
- Se reutilizan sin cambios: `ExportUserData`, `DeleteAccount`, `DeleteAccountDialog`, sus imports y el manejo de `AppException`.
- No afecta `openspec/specs/navigation-drawer` (la estructura de separadores del drawer no cambia: "Configuración" y "Cerrar sesión" siguen siendo las acciones de cuenta que quedan ahí).
