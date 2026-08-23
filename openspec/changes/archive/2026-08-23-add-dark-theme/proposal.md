## Why

El light theme de Reevo pasó por un rediseño reciente ("Dirección C": paleta ink/paper propia, `ReevoAccent` para el ámbar de no-leído/favorito, AppBar plano sin tinte de elevación). El dark theme nunca recibió ese rediseño y quedó con un `ColorScheme.fromSeed` genérico de Material 3, desconectado de la identidad visual actual. Esto no es solo estético: como `ReevoAccent` no tiene variante dark (`extensions: []` vacío en `AppTheme.dark`), el indicador de favorito (estrella) desaparece silenciosamente en la lista del inbox cuando el usuario está en dark mode — un bug funcional, no solo de diseño.

## What Changes

- Portar la Dirección C a dark: nueva paleta dark diseñada a mano (gris oscuro, no negro puro; texto casi blanco, no puro; hairline sutil) — no una inversión matemática de `_ink`/`_paper`.
- Definir `ReevoAccent.dark` con un tono de ámbar ajustado para contraste sobre fondo oscuro (no reusar el hex de light). Corrige el bug de la estrella de favorito invisible en dark.
- AppBar en dark sigue el mismo criterio que light: plano, fundido con el fondo, sin tinte de elevación M3, sin `scrolledUnderElevation`.
- Agregar una tercera opción de preferencia de tema, "seguir sistema", además de light/dark manual. `ThemeCubit` deja de mapear a un simple `ThemeMode` persistido como string binario y pasa a soportar las tres opciones.
- **BREAKING (comportamiento, no API)**: usuarios con una preferencia de tema ya guardada (`'light'` o `'dark'` explícito) se migran a "seguir sistema" en el próximo update — no se preserva la elección manual previa.
- Variante dark de la textura de papel (`paper_texture.dart`): puntos claros de bajo alpha en vez de negros, porque los puntos negros actuales son invisibles sobre fondo oscuro. Se usa en reader, inbox, favorites y sources.
- Fix de acoplamiento implícito encontrado en la auditoría: `add_source_screen.dart` tiene un `Colors.white` hardcoded en el spinner de un botón en vez de leer `colorScheme.onPrimary` del theme activo.
- Fuera de scope (evaluado y descartado): el color del fondo de swipe "marcar como leído" (`Colors.teal` en `inbox_screen.dart`) no se toca — es un color de acción semántico que funciona en ambos modos.
- Nueva pantalla mínima de Ajustes (`/settings`), con entry point desde el `NavigationDrawer`, que expone el selector de las tres opciones de tema. Hoy no existe ninguna pantalla de ajustes en la app — `ThemeCubit.toggleTheme()` no tiene ningún caller, es código sin usar.
- Dos bugs de contraste encontrados durante la verificación visual en el simulador, no cubiertos por la auditoría original de colores hardcoded (porque no son literales `Color(...)` en Dart, sino comportamiento implícito de librerías de terceros):
  - `AppTheme._textTheme` nunca tenía color explícito — Google Fonts hornea su propio color (cercano a negro) en cada `TextStyle` que devuelve, así que la resolución automática de color por brightness de `ThemeData` nunca lo pisaba (solo rellena campos nulos). Esto dejaba TODO headline/title de la app (no solo en el reader) oscuro también en dark mode. Se corrige con `.apply(bodyColor:, displayColor:, decorationColor:)` sobre el `TextTheme` base, parametrizado por color según brightness.
  - El contenido HTML de artículos (`FwhHtmlContentRenderer`) puede traer su propio color de texto inline (`style="color:..."`, atributo `color`) — común en newsletters (ej. Android Weekly le pone su propio azul a los links y su propio gris a las descripciones), calibrado contra fondo blanco y con muy bajo contraste sobre fondo oscuro. Se agrega `stripInlineTextColors`, que quita quirúrgicamente esas declaraciones con regex (sin reparsear/reserializar el HTML — un primer intento con `package:html` reestructuró el árbol de un documento mal formado y rompió el layout de un embed de YouTube) para que el theme siempre gane.

## Capabilities

### New Capabilities
- `theme-preference`: selección de modo de tema (system/light/dark), persistencia, y comportamiento de migración para usuarios existentes.

### Modified Capabilities
(ninguna — no hay specs existentes de theming; el resto del trabajo es de implementación/diseño visual sin requirements formales propios)

## Impact

- `lib/presentation/theme/app_theme.dart`: nueva paleta `AppTheme.dark`, nuevo `ReevoAccent.dark`.
- `lib/presentation/theme/theme_cubit.dart`: estado pasa de `ThemeMode` binario persistido a tres opciones (system/light/dark), lógica de migración del valor guardado en Hive (`AppConstants.settingsThemeModeKey`).
- `lib/presentation/app/app.dart`: sigue conectando `themeMode` al `MaterialApp`, sin cambios estructurales.
- `lib/core/widgets/paper_texture.dart`: variante dark de la textura.
- `lib/features/sources/presentation/screens/add_source_screen.dart`: fix de color hardcoded.
- Pantallas que consumen `ReevoAccent` (ya funcionan sin cambios una vez que `ReevoAccent.dark` existe): `lib/features/reader/presentation/screens/reader_screen.dart`, `lib/features/reader/presentation/widgets/reading_progress_bar.dart`, `lib/features/inbox/presentation/widgets/article_inbox_tile.dart`.
- `lib/presentation/app/router.dart`: nueva ruta `/settings` y entry point en el `NavigationDrawer` (junto a las demás acciones de cuenta, ej. cerca de "cerrar sesión").
- Nueva pantalla `SettingsScreen` (feature nuevo o dentro de `presentation/`, a definir en implementación) con el selector de tema de tres opciones.
- `lib/core/widgets/fwh_html_content_renderer.dart`: `stripInlineTextColors` aplicado al HTML del artículo antes de renderizarlo; simplificación del `textStyle` pasado a `HtmlWidget` (ya no necesita fijar `color` a mano, lo resuelve `_textTheme`).
