## 1. Base: dependencia y theme

- [x] 1.1 Agregar `google_fonts` a `pubspec.yaml` y correr `flutter pub get`
- [x] 1.2 Reescribir `AppTheme.light` en `lib/presentation/theme/app_theme.dart`: `ColorScheme` manual (negro `#0A0A0A` / blanco papel `#FAFAF8` / sin seed automático) y `TextTheme` combinando `GoogleFonts.newsreaderTextTheme()` (headlines) e `GoogleFonts.ibmPlexSansTextTheme()` (resto)
- [x] 1.3 Definir `ReevoAccent` como `ThemeExtension<ReevoAccent>` con el color ámbar (`unreadFavoriteAmber`) y registrarlo en `AppTheme.light`
- [x] 1.4 Dejar `AppTheme.dark` sin cambios funcionales (solo asegurar que compila con el nuevo `TextTheme` compartido si aplica), con comentario explícito de que el rediseño de dark queda fuera de alcance

## 2. Widgets base reutilizables

- [x] 2.1 Crear `core/widgets/chamfered_box.dart` (`ChamferedBox`: `ClipPath` parametrizado por `chamferSize` y esquina a cortar)
- [x] 2.2 Crear `core/widgets/paper_texture.dart` (`CustomPainter` de ruido determinístico, baja densidad/opacidad) y `PaperBackground` (widget que lo aplica como fondo de un `child`)
- [x] 2.3 Widget test de `ChamferedBox`: verifica que renderiza sin errores con distintos `chamferSize` y esquinas
- [x] 2.4 Widget test de `PaperBackground`: verifica que renderiza su `child` sin alterar el layout

## 3. `SourceIcon`

- [x] 3.1 Migrar `core/widgets/source_icon.dart` de `ClipOval` a `ChamferedBox`, manteniendo la firma pública (`iconUrl`, `name`, `size`)
- [x] 3.2 Actualizar/verificar widget tests existentes de `SourceIcon` para el nuevo shape

## 4. Inbox

- [x] 4.1 Actualizar `ArticleInboxTile`: headline con `titleMedium`/estilo serif del nuevo `TextTheme`, meta en sans
- [x] 4.2 Envolver el thumbnail de `ArticleInboxTile` en `ChamferedBox`
- [x] 4.3 Cambiar el indicador de no-leído a un mini-chaflán en color `ReevoAccent.unreadFavoriteAmber` (en vez del punto/color actual)
- [x] 4.4 Envolver `InboxScreen` (su `body`) en `PaperBackground` y agregar el logo de Reevo como marca discreta en su header — implementado en el `AppBar` compartido (`_ScaffoldWithNavBar` en `router.dart`), no en `InboxScreen` en sí: la app usa un único AppBar+Drawer para todas las pestañas, no un header por pantalla como en el mockup web. Ajustado a pedido del usuario para mostrarse en las 5 pestañas (Inbox, Favoritos, Leídos, Fuentes, Resúmenes), no solo Inbox/Favoritos
- [x] 4.5 Widget tests: `ArticleInboxTile` sigue mostrando correctamente estado leído/no-leído y thumbnail opcional

## 5. Reader

- [x] 5.1 Actualizar `ReadingProgressBar`: reemplazar el relleno continuo por una `Column` de bloques segmentados en ámbar, preservando los mismos `ValueListenable<double>`/`ValueListenable<bool>` y el comportamiento condicional de aparición
- [x] 5.2 Envolver los botones de ícono (back, favorito) de `ReaderScreen` en `ChamferedBox`
- [x] 5.3 Aplicar `ReevoAccent.unreadFavoriteAmber` al ícono de favorito cuando el artículo está marcado como favorito
- [x] 5.4 Envolver `ReaderScreen` en `PaperBackground`
- [x] 5.5 Widget test: `ReadingProgressBar` sigue reflejando el valor de progreso correctamente con el nuevo render segmentado (mismos casos de `reader-scroll-indicator`: no aparece si no hay overflow, refleja 0%/50%/100%)

## 6. Favoritos

- [x] 6.1 Envolver `FavoritesScreen` (su `body`) en `PaperBackground`
- [x] 6.2 Verificar que el ícono de favorito relleno en ámbar es visible en los tiles reutilizados de `ArticleInboxTile` dentro de esta pantalla — `ArticleInboxTile` no tenía ningún indicador de favorito; se agregó (trailing) ya que es un widget compartido con Inbox, cubierto por tests nuevos en `article_inbox_tile_test.dart`

## 7. Fuentes

- [x] 7.1 Envolver `SourcesScreen` (su `body`) en `PaperBackground`
- [x] 7.2 Envolver el `FloatingActionButton` de agregar fuente en `ChamferedBox` (o su equivalente visual chaflanado)

## 8. Verificación final

- [x] 8.1 Correr `flutter analyze` y resolver cualquier warning
- [x] 8.2 Correr `flutter test` (unit + widget) y confirmar que todo pasa
- [x] 8.3 Probar manualmente en simulador/dispositivo el golden path de Inbox → Reader → Favoritos → Fuentes, comparando contra el mockup de Dirección C — corrido en simulador iOS (iPhone 17) con datos reales de la cuenta: Inbox confirmado visualmente (paper background, headline serif, meta sans, chaflán ámbar de no-leído, thumbnails chaflanados, drawer con logo y theme). No fue posible automatizar taps a Reader/Favoritos/Fuentes en este entorno (sin `cliclick` ni acceso assistive para AppleScript); esas tres pantallas quedan verificadas por los widget tests existentes (todos en verde), no por captura visual manual. Se recomienda al usuario una revisión visual manual de esas tres pantallas antes de mergear.
