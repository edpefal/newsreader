## Why

El ícono de Reevo es hoy negro puro (`#0A0A0A`) con una "R" blanca, y el
acento in-app (indicador de no leído, estrella de favorito) es ámbar
(`#D9A441`/`#F4BB55`). Un relevamiento de la competencia directa en el App
Store (2026-09-07) mostró que ese ícono negro+glifo blanco es indistinguible
a tamaño miniatura de Matter y Readwise Reader (mismo concepto: fondo oscuro
+ letra blanca), y que el rebrand 2026 de Reeder se movió a un ámbar-naranja
muy cercano al acento actual de Reevo. Con la publicación en App Store
acercándose y los screenshots de marketing todavía sin generar, es el
momento de resolver esto antes de que el ícono nuevo tenga que rehacerse
después de los assets de marketing, no antes.

## What Changes

- Reemplazar el fondo del ícono de la app (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`, todos los tamaños) de negro puro (`#0A0A0A`) a óxido (`#C1401F`), manteniendo el mismo glifo "R" blanco.
- Reemplazar el fondo de `assets/reevo_logo.png` (mismo glifo "R", usado en `LoginScreen` y `AdaptiveShell`) de negro puro a óxido, para que coincida con el ícono nuevo.
- Cambiar `ReevoAccent.light.unreadFavoriteAmber`/`ReevoAccent.dark.unreadFavoriteAmber` en `lib/presentation/theme/app_theme.dart` de ámbar a óxido (`#C1401F` claro / `#E2794D` oscuro) — sigue siendo el único uso de `ReevoAccent` (no leído, favorito).
- Actualizar el logo ya subido al paywall de Superwall (app `53185`, paywall `255848`, proyecto `28726`) para que use el mismo asset con fondo óxido en vez del negro actual, coordinado vía `superwall-editor`.
- **Cambio de criterio (revisado tras la primera revisión manual del usuario en simulador):** el óxido deja de estar limitado a `ReevoAccent` y pasa a ser también el color de los botones/CTA primarios (`FilledButton` en las 8 pantallas que lo usan), el `FloatingActionButton` de `SourcesScreen`, el placeholder de `SourceIcon` (letra inicial cuando una fuente no tiene ícono propio), el `Badge.count` de no leídos en el drawer/rail de `AdaptiveShell` (usaba el rojo de error de Material por default), y el fondo del splash de arranque (`flutter_native_splash`, hoy `#FFFFFF`/`#121212`) — el usuario los vio en simulador todavía en negro/ink y decidió que el óxido debía tener más presencia que solo el punto de no leído y la estrella de favorito. Esto reemplaza la decisión original de "el acento nunca en botones" documentada en el comentario de `ReevoAccent`.
- `ReevoAccent` se movió de `presentation/theme/app_theme.dart` a `core/theme/reevo_accent.dart`: `SourceIcon` vive en `core/widgets/` y core no debe depender de `presentation/` (ver design.md).
- Fuera de alcance: `assets/reevo_logo_splash_light.png`/`_dark.png` (siguen siendo solo el glifo "R" sin fondo de color — no se tocan, el color de fondo del splash lo controla `flutter_native_splash` en `pubspec.yaml`) y el resto de `AppTheme` (ink/paper de fondo de pantallas, tipografía, superficies, `colorScheme.primary`/`secondary` fuera de `FilledButtonTheme`).

## Capabilities

Cambio puramente visual/de marca — no modifica ningún requirement de
comportamiento existente ni introduce una capability nueva (`skip_specs:
true` en `.openspec.yaml`).

### New Capabilities
(ninguna)

### Modified Capabilities
(ninguna)

## Impact

- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (todos los tamaños) + `Contents.json` sin cambios de estructura.
- `assets/reevo_logo.png`: mismo glifo, nuevo fondo. Afecta a `lib/features/auth/presentation/screens/login_screen.dart` y `lib/presentation/app/adaptive_shell.dart` (consumidores existentes, sin cambios de código — solo el asset).
- `lib/core/theme/reevo_accent.dart` (nuevo): clase `ReevoAccent`, movida desde `app_theme.dart` (re-exportada ahí para no romper call sites existentes).
- `lib/presentation/theme/app_theme.dart`: `filledButtonTheme` y `floatingActionButtonTheme` nuevos (óxido) en `ThemeData.light`/`.dark`.
- `lib/core/widgets/source_icon.dart`: placeholder usa `ReevoAccent` en vez de `colorScheme.primary`, con fallback si no hay `ReevoAccent` en el theme.
- `pubspec.yaml` (bloque `flutter_native_splash`) + regeneración de `ios/Runner/Base.lproj/LaunchScreen.storyboard` y equivalente Android vía `dart run flutter_native_splash:create`.
- Sistema externo: paywall de Superwall (proyecto `28726`, app `53185`, paywall `255848`) — requiere editar y volver a publicar vía `superwall-editor`, tocando el botón Publish real de la UI (ver `feedback_superwall_publish_via_api_incomplete`, publicar solo vía API queda incompleto).
- Sin impacto en backend (Supabase, Edge Functions) ni en lógica de negocio de ninguna feature.
- Los 5 screenshots de marketing para el App Store (todavía no generados) deberían producirse ya con el ícono/acento nuevos, evitando rehacerlos después de este change.
