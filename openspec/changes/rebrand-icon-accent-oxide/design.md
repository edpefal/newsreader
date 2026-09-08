## Context

`assets/reevo_logo.png` es la única fuente de la que se derivan todos los
tamaños de `ios/Runner/Assets.xcassets/AppIcon.appiconset/` vía
`flutter_launcher_icons` (`image_path: assets/reevo_logo.png`,
`android: true`, `ios: true`, `remove_alpha_ios: true` en `pubspec.yaml`).
Ese mismo PNG (fondo negro `#0A0A0A`, glifo "R" blanco, sin transparencia)
también se usa directo en `LoginScreen` y `AdaptiveShell`, y una copia
subida manualmente vive dentro del paywall de Superwall (proyecto `28726`).
`reevo_logo_splash_light.png`/`_dark.png` son un asset distinto: solo el
glifo sobre transparente, sin fondo de color, consumido por
`flutter_native_splash` — no se tocan en este change (ver proposal.md).

## Goals / Non-Goals

**Goals:**
- Recolorear el fondo de `reevo_logo.png` de negro a óxido sin alterar en
  absoluto la geometría del glifo "R" (mismas líneas, mismo anti-aliasing).
- Regenerar `AppIcon.appiconset/` reusando la herramienta ya configurada del
  proyecto (`flutter_launcher_icons`), no editando cada tamaño a mano.
- Un solo valor de óxido consistente entre ícono, `ReevoAccent` y el logo
  del paywall de Superwall.

**Non-Goals:**
- Ícono alterno para dark mode de iOS (Reevo usa un solo ícono, como hoy).
- Tocar `reevo_logo_splash_light/dark.png`, el resto de `AppTheme` (ink/paper,
  tipografía), o cualquier capability de negocio.
- Preparar Android para lanzamiento — `flutter_launcher_icons` regenera sus
  íconos como efecto colateral de compartir la misma fuente, pero Android
  sigue sin lanzarse.

## Decisions

**Recolor por luminancia (duotono), no edición manual ni regeneración por IA.**
`reevo_logo.png` es estrictamente blanco/negro con anti-aliasing en los
bordes del glifo. Un script determinista (Pillow, ya disponible) que
interpola cada píxel entre óxido y blanco según su luminancia original
(`nuevo = lerp(óxido, blanco, luminancia/255)`) preserva exactamente la
geometría y el anti-aliasing existente — sin el riesgo de una IA de imagen
generando un glifo ligeramente distinto, y sin editar 15 PNGs de
`AppIcon.appiconset/` a mano. Alternativa descartada: regenerar el logo
con una herramienta de generación de imágenes — más trabajo y riesgo de
deriva visual para un cambio que es, en esencia, un reemplazo de color
plano sobre un asset ya vectorial en espíritu (formas planas, dos tonos).

**Reusar `flutter_launcher_icons` para todos los tamaños de ícono.**
Ya está configurado apuntando a `assets/reevo_logo.png` como fuente única;
correr `dart run flutter_launcher_icons` tras recolorear ese archivo
regenera automáticamente todo `AppIcon.appiconset/` (y los íconos de
Android, ver Non-Goals) manteniendo la convención existente del proyecto en
vez de introducir un proceso paralelo.

**Mismo hex de óxido en las tres superficies.** `#C1401F` para el fondo del
ícono/logo y para `ReevoAccent.light.unreadFavoriteAmber`; `#E2794D` (más
claro y saturado, mismo criterio que ya se usaba para calibrar el ámbar
oscuro contra `_darkSurface`) para `ReevoAccent.dark.unreadFavoriteAmber`.
Sin variante de ícono para dark mode: un solo `#C1401F` en el ícono/logo,
independiente del tema del dispositivo.

**Actualizar el paywall de Superwall a mano, vía `superwall-editor`.**
El asset ya vive subido en el editor del paywall `255848`; se reemplaza por
la versión recoloreada y se publica tocando el botón Publish real de la UI
del editor (no alcanza con el endpoint `/publish`, ver
`feedback_superwall_publish_via_api_incomplete`) — mismo patrón que el
rediseño de paywall anterior (`project_superwall_paywall_redesign_2026-08-26`).

**Botones/CTAs vía `FilledButtonTheme`, no `colorScheme.primary` global.**
Cambiar `colorScheme.primary`/`secondary` (hoy `_ink`/`_darkOnSurface`) tendría
un radio de impacto impredecible: cualquier widget Material que lea
`primary`/`secondary` implícitamente (switches, radios, indicadores de tab,
etc., no solo `FilledButton`) pasaría a óxido sin haberlo decidido
explícitamente — exactamente el problema que el diseño original de
`ReevoAccent` evitaba a propósito. En su lugar, se agrega un
`filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(...))`
explícito a `ThemeData.light`/`.dark`, que solo afecta a `FilledButton`
(los 8 usos existentes en la app, ninguno con `style:` propio hoy) sin tocar
`colorScheme`. Contraste on-óxido: blanco/`_paper` en ambos temas (óxido es
suficientemente oscuro para contraste AA con texto blanco).

**Splash vía `flutter_native_splash`, regenerado con el color de fondo.**
El bloque `flutter_native_splash` de `pubspec.yaml` ya separa el color de
fondo (`color`/`color_dark`) de la imagen (`image`/`image_dark`, el glifo
sin fondo). Cambiar solo `color: "#C1401F"` y `color_dark: "#C1401F"` (mismo
valor en ambos temas — el splash es la primera impresión antes de que el
tema del dispositivo determine nada, no necesita variante oscura separada)
y correr `dart run flutter_native_splash:create` regenera los assets
nativos (`LaunchBackground.imageset` en iOS, `styles.xml`/drawables en
Android). Corrección durante la implementación: con fondo óxido en ambos
temas, el glifo negro de la variante "light" pierde contraste — `image`
pasa a apuntar también a `reevo_logo_splash_dark.png` (glifo blanco), no
solo `image_dark`.

**`ReevoAccent` se mueve a `core/theme/`, no se duplica el valor.**
`SourceIcon` (placeholder de ícono de fuente sin imagen propia) necesitaba
el mismo óxido, pero vive en `core/widgets/` -- importar `ReevoAccent` desde
`presentation/theme/app_theme.dart` violaría la regla de capas del proyecto
(core no depende de presentation). Se movió la clase a
`lib/core/theme/reevo_accent.dart` como fuente única del valor de marca;
`app_theme.dart` la re-exporta (`export ... show ReevoAccent`) para que los
4 call sites existentes en `features/*/presentation` seguían funcionando
sin tocar sus imports. `AppTheme.light`/`.dark` referencian
`ReevoAccent.light/.dark.unreadFavoriteAccent` para sus propios
`filledButtonTheme`/`floatingActionButtonTheme`, en vez de duplicar el hex
en una constante privada aparte.

**Fallback null-safe en `SourceIcon`, no `!`.** El placeholder usa
`theme.extension<ReevoAccent>()?.unreadFavoriteAccent ??
theme.colorScheme.primary` -- mismo patrón que ya existía en
`reading_progress_bar.dart` -- en vez de un null-check directo (`!`). Los
widget tests de la suite arman su propio `MaterialApp` sin `AppTheme` en
varios casos; un `!` ahí rompe cualquier pantalla que renderice
`SourceIcon` sin ese theme completo (encontrado durante la implementación:
64 tests fallando en cascada antes de aplicar el fallback).

## Risks / Trade-offs

- [Riesgo] Correr `flutter_launcher_icons` también regenera íconos de
  Android, que hoy no se usan → Mitigación: efecto colateral inofensivo
  (Android no se lanza, pero queda consistente para cuando se lance); no
  requiere trabajo extra.
- [Riesgo] El PNG recoloreado podría traer artefactos de color si el
  archivo original no fuera estrictamente blanco/negro → Mitigación:
  inspeccionar el resultado del script a resolución completa antes de
  correr `flutter_launcher_icons`, y revisar visualmente el ícono
  `1024x1024` final.
- [Riesgo] El re-upload al paywall de Superwall es manual y ya falló antes
  vía API → Mitigación: mismo flujo manual ya usado con éxito en el
  rediseño anterior (arrastrar el archivo en el editor, publicar desde la
  UI).
- [Riesgo] `#E2794D` (óxido oscuro) se eligió por criterio visual en el
  mockup de exploración, no por una fórmula de contraste verificada →
  Mitigación: revisión manual en simulador en ambos temas antes de cerrar
  el change (el usuario hace las pruebas manuales, ver
  `feedback_no_simulator_testing`).
- [Riesgo] Llevar el óxido a los botones reabre justo la puerta que
  `ReevoAccent` cerraba a propósito ("ningún widget Material lo usa
  implícitamente") → Mitigación: acotado a un `FilledButtonTheme` explícito,
  no a `colorScheme.primary`; si en el futuro se agrega un `FilledButton`
  nuevo, hereda óxido automáticamente y de forma consistente, sin volver a
  decidirlo pantalla por pantalla.

## Migration Plan

1. Script de recolor sobre `assets/reevo_logo.png` (óxido `#C1401F`).
2. `dart run flutter_launcher_icons` para regenerar `AppIcon.appiconset/`.
3. Actualizar `ReevoAccent.light`/`.dark` en `app_theme.dart`.
4. `flutter analyze` + `flutter test`.
5. Revisión manual del usuario en simulador (ícono, no leído, favorito, ambos temas).
6. Re-subir el logo recoloreado al paywall de Superwall y publicar desde la UI del editor.

Rollback: revertir el commit de Flutter (asset + 2 constantes) es directo;
del lado de Superwall, re-subir el asset negro anterior y publicar de nuevo.
