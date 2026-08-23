## Context

`AppTheme` (`lib/presentation/theme/app_theme.dart`) define `light`/`dark` como `ThemeData` estáticos. `light` es el resultado del rediseño "Dirección C" (paleta ink/paper propia, `ReevoAccent` como `ThemeExtension` para el ámbar de no-leído/favorito, AppBar plano sin tinte M3). `dark` es un `ColorScheme.fromSeed` genérico dejado como placeholder consciente (ver comentario existente en el código) y no tiene `ReevoAccent` propio (`extensions: []`), lo cual hace que `theme.extension<ReevoAccent>()` devuelva `null` en dark y rompa silenciosamente el indicador de favorito en `article_inbox_tile.dart`.

`ThemeCubit` (`lib/presentation/theme/theme_cubit.dart`) hoy es un `Cubit<ThemeMode>` que solo maneja `ThemeMode.light`/`ThemeMode.dark`, persistidos como string `'light'`/`'dark'` en la Hive box de settings bajo `AppConstants.settingsThemeModeKey`. No existe lectura de `MediaQuery.platformBrightnessOf` ni manejo de `ThemeMode.system`.

Ver proposal.md - Why / What Changes para la motivación completa y el resultado de la auditoría de colores hardcoded.

## Goals / Non-Goals

**Goals:**
- Paleta dark visualmente coherente con la identidad de Dirección C, diseñada para lectura prolongada (no negro/blanco puro).
- `ReevoAccent.dark` definido, cerrando el bug del indicador de favorito invisible.
- Tres modos de tema (claro/oscuro/sistema) con reactividad a cambios de brightness del OS en caliente.
- Migración limpia de la preferencia binaria previa a "seguir sistema".

**Non-Goals:**
- No se rediseña la tipografía (`_textTheme` es compartida entre light y dark, sin cambios).
- No se introduce theming por-usuario más allá de light/dark/system (no hay "temas custom" ni paletas alternativas).
- No se toca el color del swipe "marcar como leído" (`Colors.teal` en `inbox_screen.dart`) — evaluado y descartado en la exploración previa.
- No se resuelven otros posibles hardcodes de color fuera de los ya encontrados en la auditoría (`paper_texture.dart`, `add_source_screen.dart`); nuevos hallazgos post-merge quedan fuera de este change.

## Decisions

**Paleta dark diseñada a mano, no inversión matemática de `_ink`/`_paper`.**
Invertir `_ink` (#0A0A0A) y `_paper` (#FAFAF8) daría negro puro de fondo y blanco puro de texto. Para una app cuyo caso de uso central es lectura prolongada, negro puro como fondo grande de pantalla tiende a leerse más duro y generar halo en paneles OLED. Se define una paleta dark independiente (fondo gris muy oscuro estilo Material dark guidelines, texto casi blanco no puro, hairline gris sutil) como constantes nuevas en `AppTheme`, análogas a `_ink`/`_paper`/`_hairline` pero con su propio namespace (ej. `_darkSurface`/`_darkOnSurface`/`_darkHairline`).

**`ReevoAccent.dark` con tono ajustado, no el mismo hex que light.**
El ámbar `#D9A441` se calibró contra `_paper` (#FAFAF8). Se define un tono dark-específico (a fijar en implementación, verificando contraste contra el nuevo fondo dark) en vez de reusar el hex de light, evitando quedar con una alternativa no probada.

**AppBar dark usa el mismo criterio que light: plano, sin tinte, sin `scrolledUnderElevation`.**
Consistencia entre modos; ya es la decisión validada en light (ver memoria `feedback_appbar_flat_no_tint`), se aplica igual al color de fondo dark.

**`ThemeCubit` pasa de `Cubit<ThemeMode>` a manejar tres estados explícitos, reactivo a `WidgetsBindingObserver`/`MediaQuery`.**
`ThemeMode` de Flutter ya modela exactamente `light`/`dark`/`system` — no hace falta un enum propio, `ThemeCubit` sigue siendo `Cubit<ThemeMode>` pero ahora persiste y emite `ThemeMode.system` como estado válido (hoy el código nunca lo emite). El `MaterialApp` ya recibe `themeMode` vía `BlocBuilder` en `app.dart`, y `MaterialApp` con `themeMode: ThemeMode.system` ya resuelve automáticamente el brightness del OS y reacciona a cambios en caliente sin código adicional — no se requiere un observer manual, es comportamiento nativo de Flutter al usar `theme`/`darkTheme`/`themeMode` juntos.

**Migración: se ejecuta una vez, en la construcción de `ThemeCubit`, controlada por una key de Hive aparte (`settingsThemeModeMigratedKey`), no por el valor en sí.**
Comparar solo el valor crudo persistido (`'light'`/`'dark'` → migrar a `'system'`) no alcanza: una vez migrado, si el usuario elige explícitamente "oscuro" desde la nueva UI, el valor persistido vuelve a ser `'dark'` — indistinguible del valor legado sin una marca aparte, y la siguiente apertura lo re-migraría a `'system'`, pisando una elección deliberada post-feature. Por eso la migración se gatea con un booleano `settingsThemeModeMigratedKey` que se pone en `true` la primera vez (haya o no valor previo) y nunca se vuelve a evaluar después.

**Nueva pantalla `SettingsScreen` mínima en `/settings`, con entry point en el `NavigationDrawer`.**
No existe ninguna pantalla de ajustes hoy (`ThemeCubit.toggleTheme()` no tiene callers). En vez de meter el selector de tema directamente en el drawer (que ya tiene destinos de navegación + acciones de cuenta como "cerrar sesión", ver `router.dart`), se agrega una entrada nueva tipo `ListTile` junto a esas acciones que navega a `/settings`. La pantalla en sí, para este change, contiene únicamente el selector de tema (three-way, ej. `SegmentedButton<ThemeMode>` o un `RadioListTile` por opción) — no se agregan otras preferencias todavía, aunque la pantalla queda como punto de extensión natural para ajustes futuros.

**Variante dark de `paper_texture.dart` recibe el color como parámetro, no vía `Theme.of(context).brightness` interno al painter.**
`_PaperTexturePainter` es un `CustomPainter` sin `BuildContext` en `paint()`. La forma más simple es que `PaperBackground` (el widget) lea `Theme.of(context).brightness` una vez y pase el color de los puntos (negro bajo-alpha en light, blanco bajo-alpha en dark) al painter vía constructor — evita acoplar el painter a Material.

## Risks / Trade-offs

[La migración A (sobreescribir preferencia explícita a "system") puede sorprender a un usuario que eligió "oscuro" a propósito y cuyo OS está en modo claro durante el día] → Aceptado explícitamente en la exploración previa; es un evento único post-update, no recurrente, y el usuario puede volver a elegir "oscuro" manualmente en un toque.

[Definir un ámbar dark-específico requiere verificación visual manual de contraste, no hay una fórmula determinística en este design] → Se resuelve en implementación con revisión visual directa en el simulador antes de dar la task por terminada.

[Ampliar `ThemeCubit` a tres estados sin tests existentes rotos] → Revisar `test/` por tests que asuman el toggle binario actual (`toggleTheme()`) antes de remover o cambiar esa API pública, ya que puede haber UI (ajustes) que dependa de un método de dos vías en vez de selección de tres opciones.
