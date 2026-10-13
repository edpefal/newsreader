## Why

La tab Resúmenes lista todos los resúmenes diarios que se han generado. Con un resumen por día, la lista crece sin límite y deja de aportar: lo que el usuario quiere leer es el último. Además, un usuario nuevo ve una pantalla vacía sin saber que el resumen llegará después.

## What Changes

- La tab Resúmenes deja de mostrar una lista y muestra directamente el `DailySummary` más reciente (cabecera, tarjetas por fuente, artículos).
- Los resúmenes anteriores dejan de ser accesibles desde la UI. Siguen guardados en Hive y en Supabase y se siguen sincronizando; solo se quita su entrada en la app.
- Si no existe ningún resumen (por ejemplo, un usuario nuevo), la tab muestra un estado vacío con un texto que indica que aún no hay resúmenes y que se creará uno más adelante.
- En iPad (≥840dp) el resumen es el panel izquierdo del master-detail y el panel derecho muestra el lector del artículo abierto, o un placeholder "elige un artículo" mientras no hay ninguno.
- **BREAKING** (interno): se elimina la ruta `/summaries/:date`. El lector de artículos abierto desde el resumen pasa de `/summaries/:date/article/:articleId` a `/summaries/article/:articleId`.
- El cuerpo de `SummaryDetailScreen` se extrae sin `Scaffold`/`AppBar` para poder embeberlo en la raíz de la tab sin duplicar el chrome del shell; la fecha pasa a mostrarse dentro del contenido. La ruta del Inbox (`/summary/:id`) sigue usando el detalle con su propio `AppBar`.
- Se eliminan `SummaryListItem` y la lista de `SummariesScreen`.
- Textos nuevos o ajustados en los 3 `.arb` (en, es, fr): subtítulo del estado vacío y placeholder del panel derecho.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `daily-summaries`: el requirement "Listado de resúmenes diarios" se reemplaza por uno que muestra solo el resumen más reciente (con su estado vacío), y "Detalle de un resumen" deja de depender de seleccionar un item de una lista.
- `adaptive-master-detail`: el panel derecho de Resúmenes muestra el lector del artículo abierto desde el resumen (o un placeholder), y `/summaries/:date` deja de ser una ruta de detalle direccionable.
- `route-state-recovery`: `/summaries/:date` sale de la lista de rutas que se resuelven por identificador.

## Impact

- Código: `lib/features/summaries/` (`SummariesCubit`/`SummariesState`, `SummariesScreen`, `SummaryDetailScreen` + nuevo widget de cuerpo, eliminación de `SummaryListItem`), `lib/presentation/app/router.dart` y `branch_root_paths.dart`, `lib/l10n/*.arb`.
- Tests: `summaries_cubit_test.dart`, `summaries_screen_test.dart` y los tests del detalle y del router afectados.
- Sin cambios de servidor, de esquema ni de sincronización: no aplica la regla de orden de despliegue de clientes ya publicados.
- La tarjeta del Inbox y su ruta `/summary/:id` no cambian; abrir la tab Resúmenes sigue descartando la tarjeta de hoy, como hoy.
