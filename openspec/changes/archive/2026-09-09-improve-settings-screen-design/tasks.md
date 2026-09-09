## 1. i18n

- [x] 1.1 Agregar la clave `settingsDataAndSessionSectionTitle` en `lib/l10n/app_en.arb` (template)
- [x] 1.2 Agregar la clave `settingsDataAndSessionSectionTitle` en `lib/l10n/app_es.arb` con tuteo, sin voseo ("Datos y sesión")
- [x] 1.3 Agregar la clave `settingsDataAndSessionSectionTitle` en `lib/l10n/app_fr.arb` (placeholder en inglés, siguiendo el criterio ya usado en ese archivo)
- [x] 1.4 Correr `flutter gen-l10n` y confirmar que `AppLocalizations` expone la clave nueva

## 2. Reestructuración de `SettingsScreen`

- [x] 2.1 Agregar los getters privados `_sectionHeaderStyle`, `_rowTextStyle` y `_secondaryTextStyle` en `_SettingsScreenState`, resolviendo `titleMedium`/`bodyLarge`/`bodyMedium` del `Theme.of(context)` actual
- [x] 2.2 Aplicar `_sectionHeaderStyle` a los 3 headers de sección ("Tu cuenta", nuevo "Datos y sesión", "Apariencia"), reemplazando el uso directo de `textTheme.titleMedium`
- [x] 2.3 Reducir la sección "Tu cuenta" a email (`_secondaryTextStyle`) + línea de plan (`_rowTextStyle`) + botón de upgrade — quitar de ahí los 3 `ListTile` de acciones
- [x] 2.4 Restylear el botón "Obtener Premium" a `OutlinedButton.styleFrom` con `foregroundColor`/`side` en `Theme.of(context).extension<ReevoAccent>()!.unreadFavoriteAccent`
- [x] 2.5 Crear la sección nueva "Datos y sesión" con las 3 filas en orden Exportar → Cerrar sesión → Eliminar cuenta, cada una con `title: Text(..., style: _rowTextStyle)` (la de eliminar cuenta con `_rowTextStyle.copyWith(color: colorScheme.error)` en ícono y texto, sin `TextStyle` inline suelto)
- [x] 2.6 Separar las 3 filas con `Divider(height: 1, thickness: 1, color: colorScheme.outline)` entre cada una (no después de la última), sin `Card` ni sombra
- [x] 2.7 Verificar que la sección "Apariencia" (header + `SegmentedButton`) queda con el mismo espaciado/tratamiento que las otras dos secciones
- [x] 2.8 Ubicar "Datos y sesión" como última sección de la pantalla, después de "Apariencia" (no inmediatamente después de "Tu cuenta")
- [x] 2.9 Resaltar el label "Premium" con un badge (chip con fondo `accent`, texto en mayúsculas `colorScheme.onPrimary`) cuando la cuenta es Premium; "Free" se mantiene como texto plano

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` sin warnings nuevos
- [x] 3.2 Correr `flutter test` (incluye `test/unit/l10n/neutral_spanish_test.dart`) y confirmar que sigue en verde
- [ ] 3.3 Revisar manualmente en el simulador (a cargo del usuario) que la pantalla se ve correctamente en modo claro y oscuro, y que exportar/cerrar sesión/eliminar cuenta siguen funcionando igual que antes — **FALLÓ**: "Exportar mis datos" no reacciona al tocarlo en simulador de iPhone (no pasó nada visible). Se confirmó con un test de widget que el tap sí llega a `ExportUserData.execute()` — no es una regresión de layout de este change; la causa está más abajo en el pipeline (`ExportSourcesOpml`/`ExportFavoritesJson`/`SharePlusFileSharer`) o es preexistente. Falta el log de consola del simulador para aislar la causa raíz; queda para un change de fix aparte, no bloquea el cierre de este change de diseño.

## 4. Cierre

- [x] 4.1 Confirmar que `openspec validate --change improve-settings-screen-design --strict` pasa
- [x] 4.2 Abrir PR contra `main` y esperar el check `analyze-and-test` en verde (PR #36, verde)
- [x] 4.3 Mergear el PR (autorización permanente con CI en verde) y archivar el change en el mismo PR final (PR #36 mergeado a `main`)
