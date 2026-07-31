## Context

`ReaderScreen` (`lib/features/reader/presentation/screens/reader_screen.dart`) actualmente renderiza el contenido del artículo dentro de un `SingleChildScrollView` sin `ScrollController` ni feedback visual de progreso. El contenido puede venir de `HtmlWidget` (HTML completo) o de texto plano (excerpt/mensaje de "no disponible"), con longitud muy variable.

Según `CLAUDE.md`, `flutter_widget_from_html` no se importa directamente fuera de `core/widgets/` (se usa `HtmlContentRenderer`), pero `ReaderScreen` hoy usa `HtmlWidget` directamente — esto es deuda existente fuera del alcance de este change. El indicador de scroll no depende de esa librería, así que no se ve afectado por esa regla.

## Goals / Non-Goals

**Goals:**
- Mostrar una barra de progreso vertical fija que refleje la posición relativa del scroll (0% al inicio, 100% al final del contenido).
- Actualización fluida mientras el usuario hace scroll, sin jank perceptible.
- Ocultar el indicador cuando el contenido completo cabe en el viewport (no hay overflow).
- Mantener intacto el comportamiento existente: marcar como leído al abrir, favoritos, abrir en navegador.

**Non-Goals:**
- No se implementa un scrollbar interactivo/arrastrable (drag-to-scroll) en este change; es solo indicador de lectura, no control de navegación.
- No se persiste la posición de scroll entre sesiones.
- No se aplica a la vista web (`/article/:id/web`, que usa `ArticleWebView`/WebView nativo) — solo a la vista de lectura con contenido renderizado (`HtmlWidget`/texto).

## Decisions

**1. Widget de indicador propio en `features/reader/presentation/widgets/`, no una librería externa.**
Flutter no tiene un widget nativo de "barra de progreso de lectura"; se puede construir con un `AnimatedBuilder` escuchando un `ScrollController` y pintando un contenedor de altura proporcional. Es una pieza pequeña y específica del feature `reader`, por lo que vive en `features/reader/presentation/widgets/reading_progress_bar.dart`, no en `core/widgets/` (no envuelve ninguna librería de terceros de la tabla de abstracciones).
- Alternativa descartada: paquete de terceros (p.ej. `draggable_scrollbar`) — agrega dependencia nueva para una necesidad simple y no pasa por la tabla de abstracciones de `core/`.

**2. Cálculo de progreso vía `ScrollController` + `NotificationListener<ScrollNotification>` o listener directo.**
Se agrega un `ScrollController` al `SingleChildScrollView` existente. El progreso se calcula como `offset / (maxScrollExtent)`, clamped a `[0, 1]`. Se escucha `controller.addListener` en el `State` para actualizar un `ValueNotifier<double>` que alimenta al widget de la barra, evitando `setState` en cada frame de scroll (mejor rendimiento).
- Alternativa descartada: recalcular con `setState` en cada evento de scroll — provoca rebuilds innecesarios de todo el árbol de `ReaderScreen` (incluyendo el `HtmlWidget`, potencialmente costoso).

**3. Visibilidad condicional basada en `position.maxScrollExtent > 0`.**
Cuando el contenido no excede el viewport, `maxScrollExtent` es `0`; en ese caso la barra no se renderiza (o se renderiza con opacidad 0), evitando mostrar una barra sin utilidad.

**4. Ubicación visual: barra delgada fija en el borde derecho de la pantalla, superpuesta con `Stack`.**
Se envuelve el `body` actual del `Scaffold` en un `Stack` que agrega la barra como overlay alineado a la derecha, con `Positioned` de ancho pequeño (p.ej. 4px) y alto igual al viewport. Esto no interfiere con el `SingleChildScrollView` existente ni requiere cambiar el padding del contenido.
- Alternativa descartada: `Scrollbar` nativo de Flutter con `thumbVisibility: true` — el `Scrollbar` estándar de Material ya indica posición de scroll de forma nativa, pero su thumb es más un control de arrastre genérico que un "indicador de progreso de lectura" con la semántica visual pedida (barra de progreso). Se documenta como opción más simple en Open Questions.

## Risks / Trade-offs

- [Riesgo] Recalcular `maxScrollExtent` antes de que el layout esté completo (primer frame) puede dar un valor incorrecto → Mitigación: usar `WidgetsBinding.instance.addPostFrameCallback` o escuchar `ScrollMetricsNotification` para inicializar el estado de visibilidad tras el primer layout.
- [Riesgo] Contenido HTML con imágenes que cargan de forma asíncrona cambia `maxScrollExtent` después del render inicial → Mitigación: el `ScrollController` recalcula continuamente con cada notificación de scroll/metrics, así que el indicador se autocorrige; no requiere lógica adicional.
- [Trade-off] Usar un widget propio en vez de `Scrollbar` nativo implica más código a mantener, pero da control total sobre el estilo (grosor, color, comportamiento) acorde al diseño de la app.

## Open Questions

- ¿La barra debe usar el `Scrollbar` nativo de Material (`thumbVisibility: true`, `trackVisibility: true`) en lugar de un widget custom? Sería menos código pero menos control visual. Se opta por widget custom salvo objeción del usuario al revisar tasks.
