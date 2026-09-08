## 1. Recolorear el asset fuente

- [x] 1.1 Script de recolor por luminancia (Pillow) que interpole cada píxel de `assets/reevo_logo.png` entre óxido `#C1401F` y blanco según su luminancia original, preservando el anti-aliasing del glifo "R".
- [x] 1.2 Inspeccionar visualmente el PNG recoloreado a resolución completa (sin artefactos de color, glifo idéntico al original).
- [x] 1.3 Reemplazar `assets/reevo_logo.png` con el resultado.

## 2. Regenerar el ícono de la app

- [x] 2.1 Correr `dart run flutter_launcher_icons` para regenerar `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (y los íconos de Android como efecto colateral, ver design.md).
- [x] 2.2 Revisar visualmente el ícono `Icon-App-1024x1024@1x.png` generado.
- [x] 2.3 Confirmar que `LoginScreen` y `AdaptiveShell` (consumidores directos de `assets/reevo_logo.png`) muestran el logo nuevo sin cambios de código.

## 3. Acento in-app

- [x] 3.1 Actualizar `ReevoAccent.light.unreadFavoriteAmber` a `#C1401F` en `lib/presentation/theme/app_theme.dart`.
- [x] 3.2 Actualizar `ReevoAccent.dark.unreadFavoriteAmber` a `#E2794D`.
- [x] 3.3 Actualizar el comentario de la clase `ReevoAccent` que hoy dice "acento ámbar" para reflejar el nuevo color. Además (fuera del alcance literal de esta tarea, pero necesario para no dejar un nombre engañoso): se renombró el campo `unreadFavoriteAmber` → `unreadFavoriteAccent` en `ReevoAccent` y sus 5 call sites (`reader_screen.dart`, `reading_progress_bar.dart`, `article_inbox_tile.dart` x3, y los 2 tests que lo referencian).

## 4. Botones/CTAs, FAB, placeholder de fuente y splash de arranque

- [x] 4.1 Agregar `filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: ..., foregroundColor: ...))` a `ThemeData.light`/`.dark` en `app_theme.dart` (fondo `_oxide`/`_oxideDark`, texto `_paper`/`_darkSurface` — en dark, texto oscuro sobre el óxido más claro y saturado, mismo criterio de contraste que `ReevoAccent.dark`), sin tocar `colorScheme.primary`/`secondary`.
- [x] 4.2 Actualizar `flutter_native_splash` en `pubspec.yaml`: `color`/`color_dark` de `#FFFFFF`/`#121212` a óxido `#C1401F` (mismo valor en ambos). Corrección respecto al plan original: sí hubo que tocar `image`/`image_dark` — con fondo óxido en ambos temas, el glifo negro de `reevo_logo_splash_light.png` perdía contraste, así que se usa `reevo_logo_splash_dark.png` (glifo blanco) para ambas claves.
- [x] 4.3 Correr `dart run flutter_native_splash:create` para regenerar los assets nativos. Verificado: los 2 PNG de 1x1 de `LaunchBackground.imageset` (iOS) ya son óxido en ambos modos.
- [x] 4.4 Encontrado en revisión manual del usuario (no estaba en el plan original): el FAB de `SourcesScreen` no tenía tema explícito. Agregado `floatingActionButtonTheme` a `ThemeData.light`/`.dark`, mismo criterio que `filledButtonTheme`.
- [x] 4.5 Encontrado en la misma revisión: el placeholder de `SourceIcon` (letra inicial cuando la fuente no tiene ícono propio) usaba `colorScheme.primary` (negro) en vez del acento. Cambiado a `ReevoAccent`, con fallback a `colorScheme.primary` si no hay `ReevoAccent` registrado en el theme (mismo patrón que `reading_progress_bar.dart`).
- [x] 4.6 Refactor necesario para 4.5 sin violar capas: `ReevoAccent` vivía en `presentation/theme/app_theme.dart`, y `SourceIcon` está en `core/widgets/` (core no debe depender de presentation). Se movió la clase `ReevoAccent` a `lib/core/theme/reevo_accent.dart`; `app_theme.dart` la re-exporta para no romper los 4 call sites existentes en `features/*/presentation`.
- [x] 4.7 Regresión encontrada al correr tests tras 4.4-4.6: `SourceIcon`'s placeholder usaba `theme.extension<ReevoAccent>()!` (null-check directo), que explota en los widget tests que arman su propio `MaterialApp` sin `AppTheme` (64 tests fallando, cascada desde cualquier pantalla que renderiza `SourceIcon`). Corregido con el fallback de 4.5 antes de cerrar esta tarea.
- [x] 4.8 Encontrado en revisión manual del usuario: el `Badge.count` del contador de no leídos en el drawer/rail de `AdaptiveShell` (ej. "999+") usaba el rojo de error por default de Material, no la marca. Agregado `backgroundColor`/`textColor` explícitos (`ReevoAccent`, con el mismo fallback null-safe) en los 2 `Badge.count` (`NavigationRailDestination` y `NavigationDrawerDestination` del ítem Inbox).

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` y `flutter test` tras el acento in-app. Sin issues (`flutter analyze`), 581/581 tests OK.
- [x] 5.2 Volver a correr `flutter analyze` y `flutter test` tras el cambio de botones/splash. Sin issues, 581/581 tests OK.
- [x] 5.3 Revisión manual del usuario en simulador (ver `feedback_no_simulator_testing`). Encontró y se corrigieron en el camino: FAB de Sources (4.4), placeholder de `SourceIcon` (4.5), y el `Badge.count` de no leídos en el drawer/rail (4.8). Cerrada por el usuario.

## 6. Paywall de Superwall

- [x] 6.1 Subir el logo recoloreado al editor del paywall `255848` (proyecto `28726`) vía `begin_asset_upload`/`finish_asset_upload` (funcionó esta vez, a diferencia de la sesión anterior registrada en `feedback_superwall_publish_via_api_incomplete`), reemplazando la versión con fondo negro.
- [x] 6.1b Evaluado y aplicado: el CTA "Start Reevo Premium" estaba atado al token `primary` (`#0a0a0a`), compartido con el borde de la tarjeta de plan seleccionado. Rebindeado a un token `accent` separado (antes azul `#2563eb` sin uso, ahora óxido `#C1401F`/`#E2794D`) en vez de tocar `primary` directo — mismo criterio que `filledButtonTheme` en la app (no arrastrar el cambio a otros elementos que comparten el token).
- [x] 6.2 Publicado por el usuario tocando el botón Publish real de la UI del editor.
- [x] 6.3 Confirmado por el usuario. Además (fuera de alcance del cambio de color, pedido aparte en la misma sesión del editor): se actualizó el listado de features del paywall — agregada una línea para resumen de artículo + menciones ("Summarize any article, with mentions and links", 🔗) que faltaba, y se restauró como línea separada "New AI features as they ship" (⚡) que había quedado pisada. Orden final: resumen diario → resumen de artículo → nuevas features → cancelar cuando quieras.

## 7. Flujo de PR

- [x] 7.1 Rama `add-rebrand-icon-accent-oxide`, commit siguiendo Conventional Commits.
- [ ] 7.2 PR contra `main`, esperar CI (`analyze-and-test`) en verde.
- [ ] 7.3 Mergear, actualizar `main`, borrar la rama.
- [x] 7.4 Cerrar tareas y archivar este change en el mismo PR final (ver flujo de trabajo en CLAUDE.md).
