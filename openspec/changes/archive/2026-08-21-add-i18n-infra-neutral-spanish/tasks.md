## 1. Infraestructura base

- [x] 1.1 Agregar `flutter_localizations` (SDK) a `pubspec.yaml`, habilitar `generate: true`, y correr `flutter pub get` — hizo falta subir `intl` a `^0.20.2` (pinneado por `flutter_localizations` del SDK) y agregar un `dependency_overrides: intl: ^0.20.2` porque `webfeed_plus` lo restringe a `^0.19.0`; verificado que solo usa `DateFormat`/`date_symbol_data_local`, API estable entre versiones
- [x] 1.2 Crear `l10n.yaml` en la raíz (`arb-dir: lib/l10n`, `output-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`)
- [x] 1.3 Crear `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`, `lib/l10n/app_fr.arb` mínimos (una clave de prueba) y correr `flutter gen-l10n` para validar que la generación funciona
- [x] 1.4 Configurar `MaterialApp` en `lib/presentation/app/app.dart`: `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: [Locale('en'), Locale('es'), Locale('fr')]` (inglés primero)
- [x] 1.5 Confirmar manualmente (simulador con idioma de dispositivo en portugués, por ejemplo) que la app cae a inglés por defecto sin lógica custom — hecho junto con 13.4

## 2. Infraestructura de tests

- [x] 2.1 Crear `test/support/pump_localized_app.dart` con un helper que arma `MaterialApp`/`MaterialApp.router` con `localizationsDelegates`/`supportedLocales` de `AppLocalizations`, locale por defecto `es` — implementado como constantes reusables (`testLocale`, `testLocalizationsDelegates`, `testSupportedLocales`) en vez de una función wrapper: `MaterialApp(home:...)` y `MaterialApp.router(routerConfig:...)` tienen formas demasiado distintas para una sola función sin forzar una API rara
- [x] 2.2 Migrar los archivos de test que hoy arman su propio `MaterialApp` para usar el helper — los 15 enumerados. Se dejaron fuera a propósito `paper_texture_test.dart`, `chamfered_box_test.dart`, `source_icon_test.dart` y `route_extra_resolver_test.dart`: no muestran ningún texto traducible, agregarles la config habría sido ruido sin beneficio
- [x] 2.3 Correr `flutter test` para confirmar que la migración del helper no rompió nada antes de tocar contenido — 1 falla real detectada y corregida: `add_source_screen_test.dart` buscaba el botón de volver por `find.byTooltip('Back')`, que ahora resuelve en español al haber `localizationsDelegates` reales; cambiado a `find.byType(BackButton)` (locale-independiente). Suite completa en verde (384 tests)

## 3. Claves ARB compartidas (`common*`)

- [x] 3.1 Definir en `app_en.arb`/`app_es.arb`/`app_fr.arb` las claves genéricas reusables entre features: `commonCancel`, `commonDelete`, `commonEdit`, `commonSave`, `commonToday`, `commonYesterday`, y cualquier otra que se identifique como compartida durante la migración

## 4. Migración de texto — Inbox

- [x] 4.1 Migrar `lib/features/inbox/presentation/screens/inbox_screen.dart` (título, estados vacíos, snackbars) a `AppLocalizations` — de paso, `InboxLoading.message: String?` (texto humano hardcodeado emitido desde el Cubit) se cambió a `InboxLoading.isSyncing: bool`, ya que un Cubit no tiene `BuildContext` para localizar; el texto ahora vive en la clave `inboxSyncingSources` resuelta en la pantalla
- [x] 4.2 Migrar `lib/features/inbox/presentation/widgets/article_inbox_tile.dart` (texto no proveniente de datos del artículo) — no había nada que migrar acá aparte de "Ayer" (cubierto en el grupo 10, fechas)
- [x] 4.3 Actualizar `test/widget/features/inbox/inbox_screen_test.dart` y `test/widget/features/inbox/widgets/article_inbox_tile_test.dart` con los nuevos textos en español neutro

## 5. Migración de texto — Reader

- [x] 5.1 Migrar `lib/features/reader/presentation/screens/reader_screen.dart` (tooltips, aviso de contenido truncado) — el aviso de contenido truncado era el string con voseo detectado en explore ("Tocá acá"), ahora "Toca aquí" en `readerTruncatedContentHint`
- [x] 5.2 Actualizar `test/widget/features/reader/reader_screen_test.dart` — sin cambios necesarios, las aserciones ya buscaban por ícono/substring que sigue siendo válido

## 6. Migración de texto — Favoritos y Archivo

- [x] 6.1 Migrar `lib/features/favorites/presentation/screens/favorites_screen.dart` (estado vacío)
- [x] 6.2 Migrar `lib/features/archive/presentation/screens/archive_screen.dart` (estado vacío)
- [x] 6.3 Actualizar `test/widget/features/favorites/favorites_screen_test.dart` y `test/widget/features/archive/archive_screen_test.dart` — sin cambios necesarios, el texto ya estaba en tuteo neutro y no cambió de contenido

## 7. Migración de texto — Fuentes

- [x] 7.1 Migrar `lib/features/sources/presentation/screens/sources_screen.dart` (estado vacío, tooltip del FAB)
- [x] 7.2 Migrar `lib/features/sources/presentation/screens/add_source_screen.dart` — encontrado más voseo ("Traé", "Suscribí") corregido a tuteo; los mensajes que vienen de `AddSourceError`/`AddSourceFeedDiscoveryFailed.message` (mezcla de literales del Cubit y `AppException.message`) quedaron sin tocar, mismo bucket que el Change 3
- [x] 7.3 Migrar `lib/features/sources/presentation/screens/source_detail_screen.dart`
- [x] 7.4 Migrar `lib/features/sources/presentation/screens/import_opml_screen.dart` — varios strings con pluralización manual pasaron a ICU plural en el ARB; `ImportOpmlError.message` quedó igual que en 7.2 (mismo bucket, fuera de alcance)
- [x] 7.5 Migrar `lib/features/sources/presentation/widgets/delete_source_dialog.dart` y `edit_source_name_dialog.dart`
- [x] 7.6 Actualizar los tests correspondientes de `test/widget/features/sources/` — también estandaricé "acá" → "aquí" en el texto neutro (regionalismo del Cono Sur, mismo espíritu que corregir el voseo)

## 8. Migración de texto — Resúmenes, Auth, Account

- [x] 8.1 Migrar `lib/features/summaries/presentation/screens/summaries_screen.dart` y `summary_detail_screen.dart` (+ `summary_list_item.dart`, no listado explícitamente pero mismo texto duplicado) — voseo corregido ("Creá" → "Crea"); `SummaryGenerationError.message` sin tocar (mismo bucket que Change 3)
- [x] 8.2 Migrar `lib/features/auth/presentation/screens/login_screen.dart` — voseo corregido ("Iniciá sesión" → "Inicia sesión"); `LoginError.message` sin tocar (mismo bucket)
- [x] 8.3 Migrar `lib/features/account/presentation/widgets/delete_account_dialog.dart`
- [x] 8.4 Actualizar los tests correspondientes (`summaries_screen_test.dart`, `summary_detail_screen_test.dart`, `delete_account_dialog_test.dart`) — sin cambios necesarios, ningún test assertaba contra el texto con voseo que cambió

## 9. Migración de texto — Drawer / AppBar compartido

- [x] 9.1 Migrar los títulos de pestañas, hints de búsqueda, destinos del Drawer y acciones de cuenta (Exportar/Cerrar sesión/Eliminar cuenta) en `lib/presentation/app/router.dart` — `_titles` pasó de `static const List<String>` a un método `_titles(l10n)` ya que necesita `BuildContext`; "Inbox" se mantuvo igual en los 3 idiomas (así estaba también en el español original, no es una traducción pendiente)

## 10. Fechas localizadas

- [x] 10.1 Crear `lib/core/utils/localized_date_formatter.dart` con las funciones de fecha corta y fecha larga descritas en `design.md`, usando `commonToday`/`commonYesterday` y `DateFormat` de `intl` — 3 métodos: `dayLabel` (separadores), `articleTileDate` (tile compacto: hora/Ayer/Nd/fecha corta), `longDate` (mes abreviado + año)
- [x] 10.2 Migrar `lib/features/inbox/presentation/widgets/article_inbox_tile.dart` y `lib/core/widgets/date_separator.dart` a la nueva utilidad, eliminando su lógica propia de "Hoy"/"Ayer"
- [x] 10.3 Migrar `lib/features/reader/presentation/screens/reader_screen.dart` (fecha larga en meta del artículo) — `longDate` usa mes abreviado + año (`yMMMd`) en vez de nombre completo de mes, para no arriesgar overflow en el título y mantener el nivel de concisión del formato numérico original
- [x] 10.4 Migrar `lib/features/summaries/presentation/screens/summary_detail_screen.dart` y `lib/features/summaries/presentation/widgets/summary_list_item.dart`, eliminando los dos arrays `_months` duplicados
- [x] 10.5 Widget/unit tests: fecha larga y corta se formatean correctamente para inglés, español y francés — `test/widget/core/utils/localized_date_formatter_test.dart` (7 tests)

## 11. Regresión anti-voseo

- [x] 11.1 Test unitario que recorre los valores de `AppLocalizationsEs` y falla si alguno matchea un patrón de voseo — implementado leyendo `app_es.arb` directo (no la clase generada) en `test/unit/l10n/neutral_spanish_test.dart`, así cubre cualquier clave nueva automáticamente sin mantener una lista de getters a mano

## 12. Documentación

- [x] 12.1 Actualizar `CLAUDE.md` con la convención de i18n: dónde viven las claves ARB, cómo se agrega una nueva, y la regla de español neutro con tuteo

## 13. Verificación final

- [x] 13.1 Grep de barrido: buscar `Text('` y literales de texto de usuario remanentes fuera de `AppLocalizations` en `lib/features/**/presentation/` y `lib/presentation/`, y migrar lo que haya quedado — el barrido se extendió a `core/widgets/` (fuera del scope original de la búsqueda) y encontró 2 más: `no_search_results_state.dart` y `webview_flutter_article_web_view.dart`, ambos migrados
- [x] 13.2 Correr `flutter analyze` y resolver cualquier warning
- [x] 13.3 Correr `flutter test` (unit + widget) y confirmar que todo pasa — 392 tests, todos en verde
- [x] 13.4 Probar manualmente en simulador/dispositivo: cambiar el idioma del dispositivo entre inglés, español, francés y un idioma no soportado, y confirmar que la app responde como espera la spec de `app-localization` — probado en simulador iOS (iPhone 17) cambiando `AppleLanguages`/`AppleLocale` vía `xcrun simctl` (sin acceso de accesibilidad para navegar la UI de Ajustes). Francés: meses en francés, sufijo "j" (jour). Español: meses en español, sufijo "d". Portugués (no soportado): cae a inglés correctamente, sin lógica custom — confirma el requisito de fallback
