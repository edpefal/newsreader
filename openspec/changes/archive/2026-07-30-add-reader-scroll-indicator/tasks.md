## 1. Widget de indicador de progreso

- [x] 1.1 Crear `lib/features/reader/presentation/widgets/reading_progress_bar.dart`: widget que recibe un `ValueListenable<double>` (progreso 0.0–1.0) y un flag/valor de visibilidad, y pinta una barra vertical delgada alineada al borde derecho del contenedor.
- [x] 1.2 Usar `const` donde sea posible y `AnimatedBuilder`/`ValueListenableBuilder` para repintar solo la barra, no todo el árbol.

## 2. Integración en ReaderScreen

- [x] 2.1 En `lib/features/reader/presentation/screens/reader_screen.dart`, agregar un `ScrollController` al `State` y asociarlo al `SingleChildScrollView` existente.
- [x] 2.2 Agregar un `ValueNotifier<double>` para el progreso y un `ValueNotifier<bool>` (o combinarlo) para la visibilidad (`maxScrollExtent > 0`).
- [x] 2.3 Escuchar el `ScrollController` (`addListener`) y actualizar los notifiers calculando `offset / maxScrollExtent` clamped a `[0, 1]`; recalcular visibilidad en cada notificación.
- [x] 2.4 Inicializar el estado de visibilidad tras el primer layout (p.ej. `WidgetsBinding.instance.addPostFrameCallback`) para evitar parpadeo si el contenido ya excede el viewport desde el inicio.
- [x] 2.5 Envolver el `body` del `Scaffold` en un `Stack` que incluya el `SingleChildScrollView` existente y, superpuesto, el `ReadingProgressBar` alineado a la derecha.
- [x] 2.6 Disponer (`dispose`) el `ScrollController` y los `ValueNotifier` junto con el `_popController` existente.

## 3. Verificación manual y de regresión

- [x] 3.1 Verificar visualmente con un artículo largo (HTML extenso) que la barra aparece y avanza correctamente desde 0% hasta 100%. (cubierto por widget test con excerpt largo)
- [x] 3.2 Verificar con un artículo corto (contenido que no genera scroll) que la barra no se muestra. (cubierto por widget test)
- [x] 3.3 Verificar con un artículo sin `contentHtml` (solo excerpt o mensaje "no disponible") que el comportamiento es consistente con los casos anteriores. (cubierto por `reader_screen_test.dart` existente + nuevos tests de progreso)
- [x] 3.4 Confirmar que marcar como leído, alternar favorito y navegar a "Ver en navegador" siguen funcionando sin cambios. (suite `reader_screen_test.dart` completa sigue pasando)
- [x] 3.5 Correr `flutter analyze` y confirmar que no hay warnings nuevos.

## 4. Tests

- [x] 4.1 Agregar/actualizar widget test de `ReaderScreen` en `test/widget/` que verifique que la barra de progreso no se muestra cuando el contenido cabe en el viewport.
- [x] 4.2 Agregar widget test que simule scroll (`tester.drag` o `ScrollController.jumpTo`) sobre contenido largo y verifique que el progreso reportado por la barra cambia en consecuencia.
- [x] 4.3 Correr `flutter test test/widget/` y confirmar que pasan.
