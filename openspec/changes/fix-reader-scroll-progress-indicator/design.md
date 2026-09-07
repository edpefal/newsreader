## Context

`ReaderScreen` (`lib/features/reader/presentation/screens/reader_screen.dart`) mantiene dos `ValueNotifier` (`_scrollProgress`, `_scrollBarVisible`) que alimentan a `ReadingProgressBar`. Hoy se actualizan en dos únicos puntos: el listener del `ScrollController` (`_updateScrollProgress`, disparado en cada evento de scroll) y un `WidgetsBinding.instance.addPostFrameCallback` ejecutado una sola vez en `initState`. Ver proposal.md - Why para el detalle de por qué eso deja la barra oculta cuando el contenido crece después de ese primer frame (imágenes de `NetworkImageWidget`, embeds de YouTube, o el WebView de `_RawEmailWebView`, que reporta su alto real de forma asíncrona vía el canal `ReevoContentHeight`).

`SingleChildScrollView` no expone un callback nativo de "cambió el `maxScrollExtent`", pero sí emite un `ScrollMetricsNotification` por el árbol de widgets cada vez que el `Scrollable` que envuelve recalcula sus métricas (incluyendo cuando su `child` cambia de tamaño), sin necesidad de que el usuario haga scroll.

## Goals / Non-Goals

**Goals:**
- Que `_scrollProgress` y `_scrollBarVisible` reflejen el estado real del contenido en todo momento, incluso cuando su alto cambia después del primer frame.
- Que `ReadingProgressBar` efectivamente pinte en dispositivos/simuladores reales (ver hallazgo de verificación manual más abajo), no solo en widget tests.

**Non-Goals:**
- No se rediseña el algoritmo de progreso (proporción `pixels / maxScrollExtent`) ni la apariencia visual de la barra (mismo ancho, mismos 12 segmentos, mismos colores).
- No se agrega ningún mecanismo de polling/timer para medir tamaños (ver spec: requisito explícito en contra).
- No se resuelve el caso general de que un WebView interno (`_RawEmailWebView`, `_YoutubeWebView`) tenga su propio scroll independiente del `SingleChildScrollView` externo — ya están dimensionados con `AspectRatio`/`SizedBox` fijo una vez cargados, por lo que su alto sí se propaga al `Scrollable` externo.

## Decisions

**Envolver el `SingleChildScrollView` en un `NotificationListener<ScrollMetricsNotification>`** en vez de:
- *Alternativa descartada: `Timer.periodic` sondeando `_scrollController.position.maxScrollExtent`.* Descartada explícitamente por el requisito nuevo de la spec (no-polling) y porque introduce una ventana de latencia arbitraria además de trabajo innecesario mientras el usuario no interactúa.
- *Alternativa descartada: `LayoutBuilder`/`GlobalKey` + `RenderBox.size` sobre el `Column` de contenido.* Funciona para medir el tamaño del contenido, pero no informa cuándo cambia — igual requeriría un listener o poller adicional para saber cuándo volver a medir. `ScrollMetricsNotification` ya encapsula exactamente "las métricas de este `Scrollable` cambiaron", que es lo que se necesita.

`ScrollMetricsNotification` burbujea por el árbol cada vez que el `ScrollPosition` asociado recalcula `minScrollExtent`/`maxScrollExtent`/`viewportDimension` — lo cual ocurre automáticamente cuando el `child` del `SingleChildScrollView` cambia de tamaño (ej. una imagen termina de decodificar, o `_RawEmailWebView` hace `setState(() => _contentHeight = height)` y eso cambia el alto del `SizedBox` que lo envuelve más arriba en el árbol). El listener existente (`ScrollController.addListener`) solo se dispara ante scroll físico, no ante estos recálculos de métrica sin scroll; `ScrollMetricsNotification` sí cubre ambos casos, por lo que el listener de scroll deja de ser la única fuente de verdad.

Se reutiliza `_updateScrollProgress` (ya idempotente y barato: lee `position.pixels`/`position.maxScrollExtent` y solo escribe a los `ValueNotifier` si el valor cambia via `ValueNotifier.value =`, que ya no notifica si el valor es igual) como handler de la notificación, evitando duplicar la lógica de cálculo.

Se elimina el `addPostFrameCallback` de `initState`: con el `NotificationListener` en el árbol desde el primer `build`, el primer `ScrollMetricsNotification` (emitido cuando el `Scrollable` establece sus métricas iniciales) ya cubre el caso que el postFrameCallback resolvía manualmente.

**Reescribir `ReadingProgressBar` sin `Column`/`Expanded`** — hallazgo de la verificación manual en simulador de iOS (no previsto al escribir esta sección originalmente):

El fix de `ScrollMetricsNotification` de arriba resolvió el problema de *timing* (cuándo se recalcula `_scrollBarVisible`), confirmado con logs de depuración en dispositivo real (`maxScrollExtent` correcto, `_scrollBarVisible` en `true`). Pero la barra seguía sin pintarse en pantalla. Aislado con una serie de pruebas manuales agregando/quitando capas en el mismo `Positioned` del indicador:

- `ColoredBox` directo, `SizedBox.expand(child: ColoredBox(...))`, y `Stack`/`Positioned` anidado con `ColoredBox` → pintan correctamente, cada vez.
- `Column` con `Expanded` (la estructura original de `ReadingProgressBar`, para repartir 12 segmentos) → **no pinta ningún color**, ni con hijos de alto flexible (`Expanded`) ni de alto fijo (`SizedBox` con altura explícita). Reproducido de forma consistente en iPad Pro 11" (M5) y iPhone 17, ambos simuladores iOS 26.2, en ubicaciones distintas de la pantalla (no es específico del borde derecho).
- El resto de la pantalla usa `Column` normalmente (título, metadata) sin problema — la diferencia parece estar en `Column`/`Expanded` anidado dentro de un `Positioned` de un `Stack`, pintando `ColoredBox` puros, en este entorno (sospecha de un problema de compositing de Impeller en esta combinación específica de Flutter/iOS Simulator, no confirmado contra un issue público).

Dado que no se pudo confirmar la causa exacta a nivel de motor y que insistir en diagnosticarla no tiene retorno para este change, se optó por evitar el patrón que falló de forma reproducible: `ReadingProgressBar` arma sus 12 segmentos con `Stack`/`Positioned` (posiciones y altos calculados con `LayoutBuilder`, reemplazando el rol de `Expanded`), el único patrón que pintó de forma consistente en cada prueba manual. `AnimatedBuilder(animation: Listenable.merge([progress, visible]))` reemplaza los dos `ValueListenableBuilder` anidados originales, simplificando a un solo listener combinado; el comportamiento observable (mismos 12 segmentos, mismo color de relleno/track, misma condición de visibilidad) no cambia.

## Risks / Trade-offs

- [`ScrollMetricsNotification` no burbujea si algo entre el `child` que cambia de tamaño y el `SingleChildScrollView` intercepta la notificación (ej. otro `NotificationListener` que retorna `true`)] → No existe tal interceptor en el árbol actual de `ReaderScreen` (se verifica en la propia implementación); si se agrega uno en el futuro, deberá reenviar la notificación (`return false` o reenvío explícito).
- [Volumen de notificaciones: cada frame de una animación de layout dentro del contenido dispara una notificación] → `_updateScrollProgress` ya es una operación O(1) sin efectos secundarios costosos (solo comparación y escritura a `ValueNotifier`), así que el costo adicional es despreciable incluso con varias notificaciones por segundo durante una carga de imagen.
