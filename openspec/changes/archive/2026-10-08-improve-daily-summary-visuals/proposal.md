## Why

El detalle del resumen diario es hoy texto plano: cada fuente es solo un nombre en negrita sobre fondo liso, y los artículos son chips truncados. Es la pieza más "premium" de la app (IA, suscripción) y es la que menos identidad visual tiene. Mostrar el ícono de cada fuente y agrupar cada bloque en una tarjeta lo hace reconocible de un vistazo y consistente con Inbox, Reader y Fuentes, que ya usan `SourceIcon`.

## What Changes

- Cabecera del detalle: fila de avatares redondos apilados (los íconos de las primeras fuentes) junto a "N artículos de M fuentes", en lugar de la línea gris "N artículos resumidos".
- Cada bloque por fuente se presenta como una **tarjeta**: encabezado con `SourceIcon` chamfered a la izquierda del nombre, el nombre en negrita y el número de artículos como texto ("2 artículos"); debajo, el texto del resumen.
- Los artículos referenciados dejan de ser `ActionChip`/link suelto y pasan a **filas** con miniatura (imagen destacada del artículo), título a dos líneas y chevron. Sin imagen: recuadro neutro con ícono de documento.
- Nuevo use case `ResolveSummarySources` que resuelve `sourceId` → `NewsSource` (para su `iconUrl`) desde el repositorio local. Una fuente eliminada o desconocida cae a la inicial en óxido con el `sourceName` guardado en el bloque.
- Resúmenes sin `sourceBlocks` (anteriores a la agrupación) o bloques que no emparejan con ninguna fuente se siguen mostrando como hoy: título en negrita y texto, sin tarjeta ni ícono ni filas.
- Textos nuevos (`N artículos de M fuentes`, con plural) con sus 3 traducciones (en/es/fr).
- Sin cambios de servidor, de modelo de datos ni de sincronización.

Fuera de alcance: la tarjeta del resumen en el Inbox (`inbox-daily-summary-card`) queda para un change aparte.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `daily-summaries`: el requirement "Detalle de un resumen" cambia en cómo se presenta (cabecera con avatares y conteo de fuentes, tarjeta por fuente con ícono, filas de artículo con miniatura) y en cómo degrada (fuente eliminada, resumen sin agrupación).

## Impact

- Código: `lib/features/summaries/presentation/screens/summary_detail_screen.dart` (se divide en widgets propios, uno por archivo, bajo `features/summaries/presentation/widgets/`), nuevo `lib/features/summaries/domain/usecases/resolve_summary_sources.dart`, registro en `lib/core/di/injection.dart`, y los dos sitios de `lib/presentation/app/router.dart` que construyen `SummaryDetailScreen`.
- Reutiliza `SourceIcon` (`core/widgets/`) y `NetworkImageWidget`; no importa entre features.
- l10n: claves nuevas en `app_en.arb`, `app_es.arb`, `app_fr.arb` y regenerar con `flutter gen-l10n`.
- Tests: use case nuevo y actualización de `test/widget/features/summaries/summary_detail_screen_test.dart`.
- iPad: el detalle ya se embebe en el panel derecho; las tarjetas respetan un ancho máximo de ~680pt centrado.
