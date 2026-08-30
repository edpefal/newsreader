## Context

El warning de App Store Connect viene de que `ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png` son los PNG 1x1 transparentes que trae el template default de `flutter create`, referenciados desde `LaunchScreen.storyboard`. En Android, `launch_background.xml` solo pinta `@android:color/white` (light) o `?android:colorBackground` (dark) sin logo. Ver proposal.md - Why.

Ya existe `assets/reevo_logo.png` (1024x1024, con fondo transparente) referenciado en `pubspec.yaml` y usado como fuente del ícono vía `flutter_launcher_icons`.

## Goals / Non-Goals

**Goals:**
- Generar una launch screen nativa real en iOS y Android con el logo de Reevo centrado.
- Fondo blanco en tema claro, fondo oscuro en tema oscuro, siguiendo el tema del sistema (no el de la app, ya que la splash se muestra antes de que Flutter/el ThemeCubit puedan correr).
- Que el proceso sea repetible desde configuración declarativa (no editar XML/storyboard a mano), para que un cambio futuro de logo sea trivial.

**Non-Goals:**
- No se rediseña el ícono de la app (`flutter_launcher_icons` queda igual).
- No se agrega una "splash screen" en Dart (widget animado post-arranque); es estrictamente la launch screen nativa que exige la plataforma antes de que Flutter dibuje el primer frame.
- No se determina el color "oscuro" exacto tomándolo de `AppTheme`; se usa un color de fondo oscuro razonable definido en la config de la librería (ver Decisiones).

## Decisions

**Usar `flutter_native_splash` en vez de editar el storyboard/XML a mano.**
Es el paquete estándar de la comunidad Flutter para generar launch screens nativas en ambas plataformas desde una sola config en `pubspec.yaml` (o `flutter_native_splash.yaml`), soporta light/dark automáticamente (`android_12`, `background_image`, `dark_background`, etc.) y regenera todos los assets (`.imageset`, storyboard, `drawable*/launch_background.xml`, `values*/styles.xml`) con un solo comando (`dart run flutter_native_splash:create`). Alternativa descartada: editar `LaunchScreen.storyboard` y los `launch_background.xml` a mano — es más frágil, hay que mantener manualmente los distintos scale factors de iOS y las variantes `drawable-v21`/`values-night`, y el usuario pidió explícitamente usar una librería.

**Logo centrado sin texto ni tagline, con una variante monocromática por tema derivada de `reevo_logo.png`.**
`assets/reevo_logo.png` resultó ser un PNG completamente opaco (cuadro negro + "R" blanca, sin canal alfa real: alpha=255 en todos los píxeles), no transparente como se asumió al proponer el change. Usarlo tal cual habría dejado un recuadro negro visible sobre el fondo blanco del tema claro. Se generaron dos variantes con fondo transparente a partir del mismo arte (tratando su luminancia como máscara alfa): `assets/reevo_logo_splash_light.png` (R negra sobre transparente, para el fondo blanco) y `assets/reevo_logo_splash_dark.png` (R blanca sobre transparente, para el fondo oscuro). Alternativa descartada: dejar el cuadro negro tal cual — el usuario prefirió variantes transparentes (opción elegida explícitamente al encontrarse el problema durante la implementación).

**Color de fondo oscuro: un gris/negro neutro fijo en la config (no derivado de `AppTheme`).**
La launch screen nativa se pinta antes de que el código Dart (y por lo tanto `AppTheme`) exista, así que no puede leer el color del tema de la app en tiempo de arranque; el color va hardcodeado en la config de `flutter_native_splash`. Se documentará ese valor en `tasks.md` para que quede fácil de ajustar si no calza con `AppTheme.dark` a simple vista.

## Risks / Trade-offs

[La versión de Xcode/Flutter podría requerir el flag `android_12` para el nuevo splash API de Android 12+] → `flutter_native_splash` soporta configuración separada para `android_12` (ícono + fondo, distinto mecanismo de SplashScreen API); se configura explícitamente en vez de dejar que caiga al comportamiento legacy.

[Regenerar assets sobrescribe cualquier edición manual previa en `LaunchScreen.storyboard`/`launch_background.xml`] → Aceptable: esos archivos hoy son el placeholder default, no hay personalización que perder.

[El usuario debe verificar visualmente en simulador que el logo se ve bien centrado en ambos temas] → Documentado en CLAUDE.md que las pruebas manuales en simulador las corre el usuario, no Claude; se deja como paso explícito de verificación post-generación en tasks.md.
