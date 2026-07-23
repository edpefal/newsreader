## Why

El botón "Modo Reader" en `ReaderScreen` (ícono de libro, alterna entre el HTML renderizado y una versión en texto plano del mismo artículo) ya no aporta valor y se quita a pedido explícito.

## What Changes

- **BREAKING** (de cara al usuario, no de API): se elimina el botón "Modo Reader" del `AppBar` de `ReaderScreen`, junto con el estado y la lógica que alternaba entre HTML renderizado y texto plano stripped.
- `ReaderScreen` queda con dos acciones en el `AppBar`: favorito y "Ver en navegador" (WebView), como antes tenía tres.
- Se elimina la constante `AppConstants.settingsReaderModeKey` (`'reader_mode_enabled'`), que no estaba conectada a ningún lugar real del código (el toggle de modo reader nunca persistía su estado; era puramente local a cada apertura de `ReaderScreen`).
- Se actualiza el bullet de la sección "Características" en `README.md` que mencionaba "modo reader (texto plano)".
- Sin cambios en cómo se muestra el contenido normal (HTML renderizado vía `HtmlWidget`, con excerpt como fallback) — eso se mantiene igual, solo se quita la alternativa de texto plano y el botón que la activaba.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
(ninguna — no hay ninguna capability en `openspec/specs/` que documente el modo reader como requirement; solo se mencionaba en el README)

## Impact

- `lib/features/reader/presentation/screens/reader_screen.dart`: se elimina el `IconButton` de modo reader, el campo `_isReaderMode`, el método `_buildReaderContent`, el método `_stripHtml`, y la rama correspondiente en `_buildContent`.
- `lib/core/constants/app_constants.dart`: se elimina `settingsReaderModeKey`.
- `test/widget/features/reader/reader_screen_test.dart`: se eliminan los 4 tests dedicados al modo reader.
- `README.md`: se actualiza el bullet de "Lector" en la sección de Características.
- Sin cambios en `HtmlContentRenderer`/`FwhHtmlContentRenderer`, en Hive, ni en ningún use case.
