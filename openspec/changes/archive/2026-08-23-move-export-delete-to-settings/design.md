## Context

Hoy `_ScaffoldWithNavBarState` (en `lib/presentation/app/router.dart`) resuelve `ExportUserData` y `DeleteAccount` vía `getIt<>()` directamente dentro del widget del drawer, y maneja el flujo completo (llamar al usecase, mostrar el diálogo de confirmación, mostrar el `SnackBar` de error) ahí mismo. `SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`) es hoy un `StatelessWidget` sin lógica async.

En el resto del router, las screens (`ReaderScreen`, `SourceDetailScreen`, etc.) reciben sus usecases por constructor, resueltos con `getIt<>()` en el `GoRoute.builder`. Esa es la convención real del proyecto para resolver dependencias fuera de Bloc/Cubit, aunque difiera del texto literal de la tabla de abstracciones de `CLAUDE.md`.

## Goals / Non-Goals

**Goals:**
- Mover la UI y el flujo de "Exportar mis datos" y "Eliminar cuenta" a `SettingsScreen`, sin cambiar su comportamiento observable (mismo diálogo, mismos mensajes de error, mismo usecase).
- Mantener la convención existente de inyección por constructor resuelta en `router.dart`.

**Non-Goals:**
- No se cambia la lógica de `ExportUserData`, `DeleteAccount` ni `DeleteAccountDialog`.
- No se agregan nuevas confirmaciones ni estados de carga que no existían antes.
- No se toca el resto del contenido de `SettingsScreen` (sección de tema).

## Decisions

- **`SettingsScreen` pasa a ser `StatefulWidget`**: necesita un `State` para poder chequear `context.mounted` tras los `await` de exportar/eliminar, igual que hace hoy `_ScaffoldWithNavBarState`. Alternativa descartada: mantenerlo `StatelessWidget` y resolver todo inline en callbacks — se descarta porque el chequeo de `mounted` requiere un `State` o un `StatefulBuilder`, y esto último sería más enrevesado que convertir el widget.
- **`SettingsScreen` recibe `ExportUserData` y `DeleteAccount` por constructor**, resueltos con `getIt<>()` en el `GoRoute.builder` de `/settings` en `router.dart` — igual que el resto de las screens del router. Alternativa descartada: llamar `getIt<>()` dentro de `SettingsScreen` — se descarta para mantener consistencia con el resto de las screens ya existentes en `router.dart`.
- **Nueva sección "Cuenta" en `SettingsScreen`**, debajo de la sección de tema existente, con dos `ListTile` (exportar, eliminar cuenta) idénticos visualmente a los que hoy están en el drawer, incluyendo el color de error en el ícono/texto de "Eliminar cuenta".
- **El drawer pierde ambos `ListTile`** y sus métodos privados asociados (`_exportUserData`, `_confirmDeleteAccount`, `_deleteAccount`) en `_ScaffoldWithNavBarState`; el `Divider` y los `ListTile` de "Configuración" y "Cerrar sesión" quedan igual.

## Risks / Trade-offs

- [Duplicar el manejo de `AppException` → `SnackBar` en dos lugares durante la transición] → Mitigado porque el código se mueve, no se duplica: se elimina completamente de `router.dart` en el mismo cambio.
- [Nuevo `import` de `DeleteAccountDialog`, `ExportUserData`, `DeleteAccount`, `AppException` y `AppErrorCodeLocalizations` en `settings_screen.dart`] → Bajo riesgo, son los mismos imports que ya existían en `router.dart`.
