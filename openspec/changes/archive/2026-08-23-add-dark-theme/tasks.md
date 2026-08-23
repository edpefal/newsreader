## 1. Paleta y theme dark

- [x] 1.1 Definir constantes de paleta dark en `app_theme.dart` (fondo gris oscuro no-negro-puro, texto casi blanco no-puro, hairline gris sutil), análogas a `_ink`/`_paper`/`_hairline` pero con namespace propio para dark.
- [x] 1.2 Reescribir `AppTheme.dark` usando `ColorScheme.dark(...)` con esas constantes, replicando la estructura de `AppTheme.light` (incluyendo `secondaryContainer`/`onSecondaryContainer` para el indicador de selección del `NavigationDrawer`).
- [x] 1.3 Aplicar el mismo `AppBarTheme` plano sin tinte (`surfaceTintColor: Colors.transparent`, `elevation: 0`, `scrolledUnderElevation: 0`) al `AppTheme.dark`, con el color de fondo dark correspondiente.
- [x] 1.4 Definir `ReevoAccent.dark` con un tono de ámbar ajustado (no reusar `#D9A441`); incluir `extensions: [ReevoAccent.dark]` en `AppTheme.dark`.
- [x] 1.5 Eliminar el comentario de deuda consciente sobre dark en `app_theme.dart` que ya no aplica.

## 2. ThemeCubit: modo "seguir sistema" y migración

- [x] 2.1 Actualizar `ThemeCubit` para persistir y emitir `ThemeMode.system` además de `light`/`dark`.
- [x] 2.2 Implementar la migración idempotente en el constructor, gateada por `settingsThemeModeMigratedKey` (ver ajuste en design.md) en vez de comparar solo el valor crudo.
- [x] 2.3 Confirmar que un valor ausente (usuario nuevo) resulta en `ThemeMode.system` por defecto.
- [x] 2.4 Agregar `setThemeMode(ThemeMode)` como método público; se removió `toggleTheme()` al confirmar que no tenía ningún caller (código muerto).
- [x] 2.5 Actualizar/agregar tests unitarios de `ThemeCubit` cubriendo: estado inicial sin valor guardado, migración desde `'light'`, migración desde `'dark'`, no re-migración si ya migrado, selección explícita de cada modo.

## 3. Pantalla de Ajustes

- [x] 3.1 Crear `SettingsScreen` con el selector de tema de tres opciones (system/light/dark), conectado a `ThemeCubit`.
- [x] 3.2 Agregar la ruta `/settings` en `router.dart` (siguiendo el patrón de rutas existente).
- [x] 3.3 Agregar entry point al `/settings` en el `NavigationDrawer`, junto a las acciones de cuenta existentes (cerca de "cerrar sesión").
- [x] 3.4 Agregar las claves de localización necesarias en `app_en.arb`/`app_es.arb`/`app_fr.arb` (label de la pantalla, label de cada una de las tres opciones) y correr `flutter gen-l10n`.

## 4. Fixes de la auditoría de colores hardcoded

- [x] 4.1 `paper_texture.dart`: hacer que `PaperBackground` lea `Theme.of(context).brightness` y pase el color de los puntos (negro bajo-alpha en light, blanco bajo-alpha en dark) a `_PaperTexturePainter` vía constructor.
- [x] 4.2 `add_source_screen.dart:138`: reemplazar el `Colors.white` hardcoded del spinner por `Theme.of(context).colorScheme.onPrimary`.

## 5. Verificación visual y de regresión

- [x] 5.1 Correr la app en el simulador en modo oscuro y recorrer inbox, reader, favorites, archive, sources y la nueva pantalla de ajustes, verificando legibilidad y que no queden restos de la paleta azul genérica anterior. Verificado por el usuario en el simulador; en el camino se encontraron y corrigieron dos bugs de contraste no cubiertos por la auditoría original de colores hardcoded: el texto del reader (`HtmlWidget` no seguía `colorScheme.onSurface`) y el color de texto inline de newsletters (links y descripciones con su propio color, ej. Android Weekly) ganándole al theme -- ver `stripInlineTextColors` en `fwh_html_content_renderer.dart`. También se encontró que `_textTheme` nunca tenía color explícito (Google Fonts hornea su propio negro), afectando todos los headline/title de la app, no solo el reader -- corregido con `.apply(bodyColor:, displayColor:, decorationColor:)` en `AppTheme._textTheme`.
- [x] 5.2 Verificar específicamente que el indicador de favorito (estrella) sea visible en dark en `article_inbox_tile.dart` (el bug que motivó parte de este change). Confirmado por el usuario.
- [x] 5.3 Verificar que la textura de papel sea visible (sutil, no ausente) en dark en las 4 pantallas que la usan. Confirmado por el usuario.
- [x] 5.4 Probar el flujo de migración: instalar una build previa (o simular el valor `'light'`/`'dark'` directo en Hive), abrir con la build nueva, y confirmar que queda en "seguir sistema". Confirmado por el usuario (además de la cobertura de tests unitarios de 2.5).
- [ ] 5.5 Probar que cambiar el brightness del sistema operativo en caliente (con "seguir sistema" activo) actualiza el theme sin reiniciar la app. No verificado manualmente en esta sesión (se seteó el brightness del simulador antes de lanzar la app, no en caliente con la app ya corriendo) -- el comportamiento está garantizado por `MaterialApp(themeMode: ThemeMode.system)`, que es resolución nativa de Flutter, no código propio de este change.
- [x] 5.6 Correr `flutter analyze` y `flutter test` completos. 0 issues en analyze; 434/434 tests pasan (incluye el suite completo, no solo los tests nuevos).

## 6. Bug preexistente encontrado durante la verificación (fuera de scope)

- [ ] 6.1 Un video de YouTube embebido en un artículo (404 Media) se renderiza más chico de lo esperado. Confirmado con el usuario que es un bug preexistente no relacionado a este change (el diff de este change no toca `_YoutubeWebView`/`buildWebView`/`_wrapperHtml` en `fwh_html_content_renderer.dart`). Anotado para investigar por separado, no bloquea este change.
