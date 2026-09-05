## Why

Hoy la única forma de que un usuario descubra si su cuenta es Free o Premium es toparse con el límite del free tier al intentar generar un resumen. No hay ningún lugar en la app donde pueda consultarlo de forma proactiva, ni un punto de entrada claro para volverse Premium fuera de ese momento de fricción.

## What Changes

- Se agrega una sección nueva en `SettingsScreen`, ubicada primero (antes de la sección de tema), que muestra el estado de la cuenta: Free o Premium.
- Si la cuenta es Free, la sección muestra un botón que invita a volverse Premium y dispara el paywall remoto de Superwall (reusando el placement `daily_summary` ya existente, sin crear un placement nuevo).
- Si la cuenta es Premium, la sección solo muestra el estado, sin botón.
- Se agregan las claves de copy nuevas en los 3 `.arb` (inglés, español neutro, francés con placeholder) y se corre `flutter gen-l10n`.
- La sección de cuenta y la sección de tier se fusionan en una sola sección ("Tu cuenta"): título, email de la cuenta autenticada (`AuthClient.currentUserEmail`), estado Free/Premium (+ botón de upgrade si es Free), y debajo las acciones de cuenta existentes (exportar datos, eliminar cuenta, cerrar sesión). Se elimina el título "Cuenta" duplicado (`settingsAccountSectionTitle`, ya sin uso).

## Capabilities

### New Capabilities
- `settings-account-status`: sección en Ajustes que muestra el tier de la cuenta (Free/Premium) y, si es Free, un botón para iniciar el flujo de upgrade a Premium vía el paywall remoto de Superwall.

### Modified Capabilities
(ninguna — no cambia el comportamiento de `subscription-entitlements` ni de ningún otro spec existente; solo se agrega una superficie de UI nueva que lee el estado ya expuesto por `SubscriptionStatusProvider`)

## Impact

- `lib/features/settings/presentation/screens/settings_screen.dart`: recibe un `SubscriptionStatusProvider` nuevo por constructor y renderiza la sección nueva primero.
- Punto donde se instancia `SettingsScreen` (router/DI): debe pasar el `SubscriptionStatusProvider` ya registrado en `core/di/injection.dart`.
- `lib/l10n/app_en.arb`, `app_es.arb`, `app_fr.arb`: nuevas claves de copy (título de sección, estado Free, estado Premium, botón de upgrade).
- Sin cambios de backend, de esquema de datos, ni de la interfaz `SubscriptionStatusProvider`.
