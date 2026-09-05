## 1. Copy (i18n)

- [x] 1.1 Agregar en `lib/l10n/app_en.arb`, `app_es.arb` (contenido real, español neutro con tuteo) y `app_fr.arb` (placeholder en inglés) las claves nuevas: título de sección (ej. `settingsAccountTierSectionTitle`), estado Free (ej. `settingsAccountTierFree`), estado Premium (ej. `settingsAccountTierPremium`) y texto del botón de upgrade (ej. `settingsAccountTierUpgradeButton`, alineado con el tono de `articleSummaryFreeTierExhaustedButton`).
- [x] 1.2 Correr `flutter gen-l10n` y confirmar que `lib/l10n/app_localizations.dart` incluye las claves nuevas.

## 2. SettingsScreen

- [x] 2.1 Agregar `SubscriptionStatusProvider` como parámetro requerido del constructor de `SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`).
- [x] 2.2 Construir la sección de estado de cuenta como la primera sección del `Column` en `build()`, antes de la sección de tema (`settingsThemeSectionTitle`): título de sección + texto "Free" o "Premium" según `subscriptionStatusProvider.isSubscribed`.
- [x] 2.3 Cuando `isSubscribed` es `false`, mostrar el botón de upgrade; al tocarlo, llamar `subscriptionStatusProvider.showPaywall(onSubscribed: () { if (mounted) setState(() {}); })`.
- [x] 2.4 Cuando `isSubscribed` es `true`, no mostrar ningún botón de upgrade en la sección.
- [x] 2.5 Mostrar el email de la cuenta autenticada (`widget.authClient.currentUserEmail`) en la sección de cuenta.
- [x] 2.6 Fusionar la sección de tier y la sección "Cuenta" en una sola sección (título, email, estado Free/Premium + botón, acciones de cuenta), y eliminar el título duplicado `settingsAccountSectionTitle` (y la clave de los 3 `.arb`, ya sin uso).

## 3. Wiring

- [x] 3.1 En `lib/presentation/app/router.dart`, pasar `subscriptionStatusProvider: getIt<SubscriptionStatusProvider>()` a la instanciación de `SettingsScreen`.

## 4. Tests

- [x] 4.1 Agregar/actualizar widget tests de `SettingsScreen` (con `MockSubscriptionStatusProvider` vía `mocktail`) cubriendo: cuenta Free muestra "Free" + botón de upgrade; cuenta Premium muestra "Premium" sin botón; tocar el botón invoca `showPaywall`; tras completar la compra (`onSubscribed` corre y `isSubscribed` pasa a `true`) la sección se actualiza a "Premium" sin reconstruir el widget desde cero.
- [x] 4.2 Correr `flutter analyze` y `flutter test` y confirmar que no hay warnings ni tests rotos.

## 5. Cierre

- [ ] 5.1 Verificar manualmente en simulador (lo hace el usuario, no automatizar) que la sección aparece primero en Ajustes y el flujo de upgrade funciona de punta a punta.
- [ ] 5.2 Seguir el flujo de git de CLAUDE.md: rama nueva, PR contra `main`, esperar CI en verde, mergear, y solo después archivar este change (`/opsx:archive`) en el mismo PR final que cierra `tasks.md`.
