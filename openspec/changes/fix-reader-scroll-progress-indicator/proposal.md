## Why

`ReaderScreen` ya tiene un indicador vertical de progreso de lectura (`ReadingProgressBar`, capability `reader-scroll-indicator`), pero su visibilidad y posición se calculan una sola vez justo después del primer frame (`WidgetsBinding.instance.addPostFrameCallback`) y luego solo se actualizan cuando el usuario hace scroll. El alto real del contenido de un artículo casi nunca está definitivo en ese primer frame: imágenes remotas (`NetworkImageWidget`), embeds de YouTube y el WebView de newsletters crudos (`_RawEmailWebView`, que reporta su alto de forma asíncrona vía `ReevoContentHeight`) terminan de cargar después y cambian el alto total del contenido. Si en el primer frame el contenido todavía cabe en el viewport, `_scrollBarVisible` queda en `false` para siempre aunque el contenido termine siendo más largo que la pantalla, dejando al usuario sin ninguna señal de cuánto le falta por leer — el síntoma reportado ("la barra se perdió").

## What Changes

- `ReaderScreen` recalcula el progreso y la visibilidad del indicador (`_scrollProgress`, `_scrollBarVisible`) cada vez que cambia el alto total del contenido scrolleable, no solo en el primer frame y en eventos de scroll — usando `NotificationListener<ScrollMetricsNotification>` (o equivalente) sobre el `SingleChildScrollView` para detectar cambios de `maxScrollExtent` producidos por contenido que termina de cargar de forma asíncrona.
- `ReadingProgressBar` se reescribe internamente para dejar de usar `Column`/`Expanded`: en pruebas manuales en simulador de iOS (Impeller) ese patrón no llegaba a pintar ningún color dentro del `Positioned` del indicador, con o sin `Expanded` (ver design.md - Decisiones). Se reemplaza por `Stack`/`Positioned` con `LayoutBuilder`, que sí pintó de forma consistente en cada prueba manual. El contrato del widget (misma API pública, mismo resultado visual esperado) no cambia.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `reader-scroll-indicator`: se agrega el requisito de que el indicador refleje correctamente la visibilidad y el progreso cuando el alto del contenido cambia después del primer frame (carga asíncrona de imágenes, embeds o WebViews), no solo en la carga inicial y en eventos de scroll del usuario.

## Impact

- `lib/features/reader/presentation/screens/reader_screen.dart`: lógica de cálculo de `_scrollProgress` / `_scrollBarVisible`.
- `lib/features/reader/presentation/widgets/reading_progress_bar.dart`: reescritura interna del layout de los segmentos (`Stack`/`Positioned` en vez de `Column`/`Expanded`); misma API pública (`progress`, `visible`) y mismo resultado visual esperado.
- Sin impacto en rutas, otros features, ni en datos persistidos.
