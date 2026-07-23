## Context

`ReaderScreen` (`lib/features/reader/presentation/screens/reader_screen.dart`) tiene un `IconButton` con ícono `Icons.chrome_reader_mode`/`Icons.chrome_reader_mode_outlined` que alterna un campo local `_isReaderMode` (`bool`, no persistido). Cuando está activo, `_buildContent` llama a `_buildReaderContent`, que hace un strip manual de tags HTML (regex propia, no usa `HtmlToPlainText` de `core/utils/` porque ese cambio es posterior a este código) y muestra el resultado como texto plano en vez del `HtmlWidget` renderizado.

Existe además una constante `AppConstants.settingsReaderModeKey = 'reader_mode_enabled'` que sugiere que en algún momento se planeó persistir esta preferencia en Hive, pero nunca se conectó — no hay ningún `read`/`write` a esa key en todo el código. Es dead code independiente del botón, pero directamente asociado al mismo feature.

## Goals / Non-Goals

**Goals:**
- Quitar el botón y toda la lógica de modo reader de `ReaderScreen`, dejando el comportamiento normal (HTML renderizado, excerpt como fallback) intacto.
- Limpiar la constante muerta asociada.
- Dejar el archivo sin código muerto residual (métodos `_buildReaderContent`/`_stripHtml` que ya no tendrían ningún caller).

**Non-Goals:**
- No se toca el botón "Ver en navegador" (WebView) ni el de favoritos — quedan igual.
- No se toca `HtmlContentRenderer`/`FwhHtmlContentRenderer` ni cómo se renderiza el HTML normal.
- No es necesaria ninguna migración de datos: al no haber persistencia real de `_isReaderMode`, no hay estado guardado en Hive que limpiar.

## Decisions

### Eliminar en vez de ocultar tras un flag
Se elimina el código directamente (botón, estado, métodos auxiliares) en vez de dejarlo detrás de un feature flag o comentado. Es una función sin usuarios que dependan de su persistencia (no existe tal persistencia) y sin ningún otro lugar del código que la referencie — no hay razón para mantenerla como código muerto.

### Eliminar `settingsReaderModeKey` como parte del mismo change
Aunque no está directamente en el `AppBar`, es una constante que solo existe por este feature y no se usa en ningún otro lado. Dejarla generaría confusión futura (¿por qué existe una key de settings para algo que no se persiste?). Se limpia en el mismo change en vez de dejarla como deuda técnica separada.

## Risks / Trade-offs

- **[Riesgo] Ninguno relevante** — es una eliminación acotada a un único archivo de pantalla y sus tests, sin dependencias de otros features ni de datos persistidos.

## Migration Plan

Sin migración de datos (no había estado persistido). Se elimina el código, se actualizan/eliminan los tests correspondientes, y se verifica manualmente que `ReaderScreen` sigue funcionando bien (favoritos, ver en navegador, contenido HTML) sin el botón de modo reader.
