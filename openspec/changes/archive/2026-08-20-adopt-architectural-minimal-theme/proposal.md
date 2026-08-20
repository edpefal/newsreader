## Why

El theme actual (`AppTheme`) es Material 3 genérico: `ColorScheme.fromSeed` con un azul de stock (`#2563EB`) y sin tipografía distintiva. No refleja la identidad de marca (el logo de Reevo es una "R" geométrica, muy angulosa, blanco puro sobre negro puro) ni la naturaleza de la app como lector de artículos. Se exploraron dos direcciones visuales en un canvas de mockups (Dirección A "Diario editorial" y Dirección C "Arquitectónico minimal") y el usuario eligió la Dirección C.

## What Changes

- Reemplazar el `ColorScheme` actual (seed azul) por una paleta negro puro / blanco papel / acento ámbar disciplinado, coherente con el negro del logo.
- Reemplazar el `TextTheme` por defecto de Material por un par tipográfico: serif con carácter (Newsreader) para headlines de artículo y nombres de fuente, sans-serif neutro (IBM Plex Sans) para todo el chrome de UI — vía `google_fonts`.
- Introducir un detalle de sistema recurrente ("chaflán": esquina cortada en diagonal vía `ClipPath`, en vez de `border-radius`) en: thumbnails de artículo, ícono de fuente (pasa de circular a chaflanado), botones de ícono del Reader (back, favorito), el FAB de agregar fuente, y el indicador de no-leído.
- Restringir el acento ámbar a exactamente dos usos funcionales: el indicador de artículo no leído, y el estado de favorito (relleno cuando está marcado). Ningún otro elemento usa el acento.
- Cambiar la barra de progreso de lectura (`ReadingProgressBar`) de una barra continua a un indicador segmentado de bloques rectangulares en ámbar.
- Agregar una textura de papel sutil como fondo de las pantallas principales.
- Agregar el logo de Reevo como marca discreta en el header de Inbox y Favoritos.
- El alcance visual es explícitamente **light mode**; el modo dark queda fuera de este change (ver Impact).

Ningún comportamiento, flujo de navegación o regla de negocio cambia — es un cambio puramente visual/de presentación.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

Ninguna. Los requisitos funcionales existentes (p.ej. `reader-scroll-indicator`, que solo exige que el indicador refleje la posición de scroll, sin prescribir su forma visual) no cambian — este change solo altera la implementación visual dentro de los límites ya establecidos por esos requisitos.

## Impact

- **Código afectado**: `lib/presentation/theme/app_theme.dart` (ColorScheme + TextTheme nuevos); `lib/features/inbox/presentation/widgets/article_inbox_tile.dart`; `lib/features/reader/presentation/screens/reader_screen.dart` y `lib/features/reader/presentation/widgets/reading_progress_bar.dart`; `lib/features/favorites/presentation/screens/favorites_screen.dart`; `lib/features/sources/presentation/screens/sources_screen.dart` y `core/widgets/source_icon.dart`.
- **Nueva dependencia**: `google_fonts` (a agregar a `pubspec.yaml` si no está presente).
- **Sin cambios de datos**: no afecta modelos de Hive, sincronización, ni ningún use case.
- **Fuera de alcance**: pantallas de Archivo, Fuentes (add/detail/import OPML), Auth, Account, Summaries — heredan el `ColorScheme`/`TextTheme` global automáticamente, sin cambios de layout dedicados. Dark mode queda fuera de alcance de este change (el `AppTheme.dark` actual se mantiene sin rediseñar; una nota técnica se deja en `design.md`).
