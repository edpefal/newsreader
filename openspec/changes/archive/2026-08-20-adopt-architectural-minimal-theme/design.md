## Context

Ver `proposal.md` - Why. Puntos técnicos relevantes del estado actual:

- `AppTheme` (`lib/presentation/theme/app_theme.dart`) expone `light` y `dark` con `ColorScheme.fromSeed` y un `TextTheme` mínimo, consumidos vía `Theme.of(context)` en toda la app.
- `SourceIcon` (`core/widgets/source_icon.dart`) es un widget **compartido** (regla de abstracciones de `CLAUDE.md`): se usa en Inbox, Favoritos, Reader y Sources. Un cambio ahí propaga a las cuatro features sin tocarlas individualmente.
- `ReadingProgressBar` (`features/reader/presentation/widgets/reading_progress_bar.dart`) es una barra **vertical** pegada al borde derecho de la pantalla, no horizontal — así lo fija `openspec/specs/reader-scroll-indicator/spec.md` ("barra de progreso vertical"). El mockup del canvas mostraba un tratamiento horizontal segmentado a modo exploratorio; este design adapta esa idea (bloques discretos en vez de un relleno continuo) a la orientación vertical existente, sin tocar el contrato de comportamiento del spec.
- No hay dependencia de `google_fonts` en `pubspec.yaml` hoy.
- No existe ningún mecanismo de textura/ruido en la app; se implementa desde cero.

## Goals / Non-Goals

**Goals:**
- Centralizar toda la definición de la Dirección C (colores, tipografía, chaflán) en `AppTheme` y un pequeño conjunto de constantes/extension reutilizables, para que las features la consuman sin reinventar valores.
- Aplicar el chaflán y el acento ámbar de forma consistente en los widgets ya identificados en el proposal, sin duplicar lógica de `ClipPath` en cada feature.
- Mantener intacto el comportamiento de `reader-scroll-indicator` (orientación vertical, aparición condicional, actualización en tiempo real).

**Non-Goals:**
- No se rediseña `AppTheme.dark` en este change (ver Risks).
- No se introduce un design token system formal (no hay Figma tokens ni generador); los valores viven como constantes Dart documentadas.
- No se cambia ningún use case, Bloc/Cubit, ni modelo de datos.
- No se optimiza la textura de papel más allá de "sutil y liviana" — no se persigue realismo fotográfico.

## Decisions

### 1. Paleta y tipografía centralizadas en `AppTheme`
`AppTheme.light` pasa a construirse con un `ColorScheme` manual (no `fromSeed`): `primary`/`onSurface` = negro puro (`#0A0A0A`), `surface` = blanco papel (`#FAFAF8`), `tertiary` (o un color custom vía `ThemeExtension`) = ámbar (`oklch(78% 0.15 85)` convertido a sRGB para Flutter, que no soporta oklch nativo). El `TextTheme` usa `GoogleFonts.newsreaderTextTheme()` para `headline*`/`titleLarge` (headlines de artículo, nombres de fuente) y `GoogleFonts.ibmPlexSansTextTheme()` para el resto, combinados con `.merge()`.

**Alternativa considerada**: mantener `ColorScheme.fromSeed` con un seed negro. Se descarta porque `fromSeed` genera automáticamente variantes tonales (surface containers, etc.) que no coinciden con la paleta de dos tonos + un acento que pide la Dirección C; un `ColorScheme` explícito da control total sobre esos tres valores.

### 2. El acento ámbar vive en un `ThemeExtension<ReevoAccent>`, no en `colorScheme.secondary`
Para que el acento quede reservado exclusivamente a "no leído" y "favorito" (regla explícita del proposal) y no se filtre accidentalmente a otros widgets que consumen `colorScheme.secondary`/`tertiary` por defecto (switches, chips, etc. de Material), se define una `ThemeExtension` propia (`ReevoAccent.unreadFavoriteAmber`) que solo los dos widgets afectados (`ArticleInboxTile`, `ReadingProgressBar`, ícono de favorito del Reader) consultan explícitamente.

**Alternativa considerada**: usar `colorScheme.tertiary`. Se descarta porque varios widgets Material por defecto (indicadores de foco, `Switch`, etc.) leen `tertiary`/`secondary` implícitamente, arriesgando fugas del acento fuera de los dos usos permitidos.

### 3. Chaflán como widget reutilizable `ChamferedBox` en `core/widgets/`
Se agrega `core/widgets/chamfered_box.dart`: un widget que envuelve a un `child` con un `ClipPath` de esquina cortada, parametrizado por tamaño de corte (`chamferSize`) y qué esquina(s) cortar. Es el único lugar donde vive la matemática del `clip-path`. `SourceIcon`, los thumbnails de `ArticleInboxTile`, los botones de ícono del Reader y el FAB de Sources lo consumen en vez de reimplementar `ClipPath`/`CustomClipper` cada uno.

**Alternativa considerada**: aplicar `ClipPath` inline en cada widget consumidor. Se descarta por duplicación (5 lugares) y porque cualquier ajuste futuro al ángulo/tamaño del chaflán tendría que tocar 5 archivos en vez de 1 — viola la regla de abstracciones del proyecto (una sola fuente de verdad para un detalle visual de marca).

### 4. `SourceIcon` cambia de `ClipOval` a `ChamferedBox`
Es un cambio directo dentro del widget compartido existente; no requiere tocar los call sites en Inbox/Favoritos/Reader/Sources porque la firma pública (`iconUrl`, `name`, `size`) no cambia.

### 5. `ReadingProgressBar` pasa de relleno continuo a segmentos verticales
Se reemplaza el único `ColoredBox` de relleno por una `Column` de N bloques (`_ReadingProgressBar._segmentCount`, valor fijo razonable, p.ej. 10) donde cada bloque se pinta en ámbar si su fracción acumulada es `<= progress.value`, y en `surfaceContainerHighest` si no. Mantiene el `ValueListenableBuilder<double>` existente (mismo `progress`/`visible` listenables, mismo comportamiento condicional) — solo cambia el `builder` interno.

**Alternativa considerada**: mantener el relleno continuo y solo cambiar el color. Se descarta porque el mockup validado por el usuario usa explícitamente bloques discretos como parte del lenguaje visual angular del sistema (Decisión de diseño ya tomada en la fase de exploración, no una decisión abierta aquí).

### 6. Textura de papel vía `CustomPainter` con ruido pregenerado, no assets de imagen
Se implementa `core/widgets/paper_texture.dart`: un `CustomPainter` que dibuja puntos/ruido de baja densidad con opacidad muy baja (~3-5%) sobre el `surface`, usando una semilla fija (`Random(42)`) para que el patrón sea determinístico entre rebuilds y no cause jank. Se aplica como fondo de Inbox, Favoritos, Reader y Sources mediante un widget `PaperBackground` que envuelve el `body` del `Scaffold`.

**Alternativa considerada**: un asset PNG tileable (como se usó en el mockup HTML vía SVG `feTurbulence`). Se descarta porque el mockup corre en un navegador (SVG nativo); en Flutter un asset de imagen agrega peso al bundle y una dependencia de generación externa, mientras que un `CustomPainter` con ruido pseudo-aleatorio determinístico es liviano, no requiere assets nuevos, y es trivial de ajustar (densidad/opacidad como parámetros).

### 7. `google_fonts` como nueva dependencia
Se agrega a `pubspec.yaml`. Es la vía estándar en Flutter para tipografía de Google Fonts con carga/cache automática y fallback a system fonts mientras descarga — evita empaquetar archivos de fuente manualmente.

## Risks / Trade-offs

- **[Riesgo] `google_fonts` descarga las tipografías en runtime la primera vez (requiere red) y podría mostrar un flash de fuente de sistema.** → Mitigación: usar `GoogleFonts.newsreaderTextTheme()`/`ibmPlexSansTextTheme()` que Flutter cachea localmente tras la primera carga; aceptable dado que la app ya depende de red para sincronizar feeds. Si se vuelve un problema perceptible, una iteración futura puede empaquetar las fuentes como assets locales (`.ttf` + `pubspec.yaml`), pero no es necesario para este change.
- **[Riesgo] El `ThemeExtension` de acento y `ChamferedBox` son abstracciones nuevas que otros desarrolladores deben descubrir y reusar correctamente, o el acento/chaflán se vuelve inconsistente con el tiempo.** → Mitigación: documentar brevemente en el propio archivo (`chamfered_box.dart`, comentario de una línea en la `ThemeExtension`) dónde deben usarse; no se agregan tests de lint automatizados para esto — está fuera de alcance.
- **[Riesgo] `AppTheme.dark` queda desalineado visualmente respecto al nuevo `AppTheme.light` (paleta y tipografía distintas) hasta que se rediseñe.** → Mitigación: no es una regresión funcional (dark mode sigue siendo Material 3 coherente en sí mismo), solo una inconsistencia de marca temporal. Se deja como trabajo futuro explícito, no bloqueante para este change.
- **[Trade-off] Restringir el ámbar a una `ThemeExtension` en vez de `colorScheme.tertiary` agrega un paso extra (`Theme.of(context).extension<ReevoAccent>()`) en los tres call sites que lo usan**, en vez de la ergonomía de `colorScheme.tertiary` directo. Se acepta porque la disciplina de "solo dos usos" es un requisito explícito del proposal y vale la fricción menor.

## Migration Plan

- Cambio de una sola pasada, sin flag de feature ni rollout gradual (es puramente visual, no hay estado persistido que migrar).
- Orden de implementación sugerido (ver `tasks.md`): (1) `AppTheme` + dependencia `google_fonts` + `ThemeExtension` de acento, (2) `ChamferedBox` + `PaperBackground` en `core/widgets/`, (3) `SourceIcon` migrado a `ChamferedBox`, (4) `ArticleInboxTile` (headline serif, thumbnail chaflanado, indicador no-leído ámbar), (5) `ReadingProgressBar` segmentado + botones del Reader chaflanados + logo en header, (6) `SourcesScreen` FAB chaflanado, (7) `FavoritesScreen` (favorito ámbar visible).
- Rollback: revertir el commit/PR del change; no hay migración de datos que deshacer.
- Verificación: `flutter analyze` sin warnings, `flutter test` (unit + widget) en verde, y una pasada visual manual en simulador/dispositivo de Inbox, Reader, Favoritos y Sources (el CLAUDE.md del proyecto exige probar el golden path en el emulador antes de dar por cerrado un cambio de UI).
