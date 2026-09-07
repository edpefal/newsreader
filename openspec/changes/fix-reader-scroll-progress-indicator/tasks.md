## 1. Implementación

- [x] 1.1 Envolver el `SingleChildScrollView` de `ReaderScreen` en un `NotificationListener<ScrollMetricsNotification>` que invoque `_updateScrollProgress` en cada notificación y deje que siga burbujeando (`return false`).
- [x] 1.2 Eliminar el `WidgetsBinding.instance.addPostFrameCallback(() => _updateScrollProgress())` de `initState`, ya cubierto por la primera `ScrollMetricsNotification` emitida al establecer las métricas iniciales.
- [x] 1.3 Confirmar que `_updateScrollProgress` sigue siendo seguro de llamar desde ambas fuentes (listener de `ScrollController` y `NotificationListener`) sin lógica duplicada ni condiciones de carrera (es idempotente: solo lee `position.pixels`/`position.maxScrollExtent` y escribe a los `ValueNotifier`).

## 2. Tests

- [x] 2.1 Agregar un widget test en `test/widget/features/reader/` que simule contenido cuyo alto crece después del primer frame (ej. un `FutureBuilder`/`setState` diferido dentro de un fake que reemplaza al contenido real) y verifique que `ReadingProgressBar` pasa a visible sin que el test dispare un scroll manual.
- [x] 2.2 Agregar/actualizar un widget test que cubra el escenario inverso: contenido que inicialmente excede el viewport y luego se reduce por debajo, verificando que la barra deja de mostrarse.
- [x] 2.3 Verificar que los tests existentes de `ReaderScreen` (marcar como leído, favorito, navegación a WebView) siguen pasando sin cambios.

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` y `flutter test` localmente.
- [x] 3.2 Probar manualmente (el usuario, en simulador) un artículo largo y confirmar que la barra aparece — reveló un segundo problema no anticipado: ver tarea 4.
- [x] 3.3 Confirmar en simulador, con build limpio (`flutter clean` + `flutter run`), que la barra se ve correctamente tras la tarea 4.

## 4. Fix de pintura de `ReadingProgressBar` (hallado durante la verificación manual)

- [x] 4.1 Diagnosticar por qué la barra no pintaba pese a que `_scrollBarVisible`/`_scrollProgress` tenían los valores correctos (ver design.md - Decisiones): aislado a `Column`/`Expanded` dentro del `Positioned` del indicador, reproducido en dos simuladores iOS distintos.
- [x] 4.2 Reescribir `ReadingProgressBar` usando `Stack`/`Positioned`/`LayoutBuilder` en vez de `Column`/`Expanded`, manteniendo la misma API pública y el mismo resultado visual (12 segmentos, mismo ancho y colores).
- [x] 4.3 Confirmar que `test/widget/features/reader/reading_progress_bar_test.dart` y los tests de `reader_screen_test.dart` (incluidas las tareas 2.1/2.2) siguen pasando contra la reescritura.
