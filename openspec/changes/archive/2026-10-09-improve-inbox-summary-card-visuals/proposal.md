## Why

La tarjeta del resumen de hoy en el Inbox es la puerta de entrada al resumen, pero sus avatares son solo la inicial de cada fuente sobre un círculo translúcido, que sobre el óxido se lee como un círculo gris. Ahora que el detalle del resumen muestra el ícono real de cada fuente (change `improve-daily-summary-visuals`), la tarjeta debe mostrar los mismos íconos para que la entrada y el detalle se reconozcan como lo mismo, y debe dejar claro de un vistazo que es un resumen generado por IA.

## What Changes

- Los avatares de la tarjeta muestran el **ícono real** de cada fuente (`iconUrl`), recortado en círculo y con el anillo del color de fondo; cuando la fuente no tiene ícono o ya no existe, conservan la inicial sobre el círculo translúcido de hoy. Pasan de 28 a 34px.
- Un **ícono de destello** (IA) a la izquierda del título "Resumen de hoy", decorativo.
- El radio de la tarjeta pasa de 12 a **14**, igual que las tarjetas del detalle del resumen (también el borde del estado seleccionado y el fondo del swipe).
- El inbox obtiene los íconos de las fuentes del resumen sin consultas extra: `InboxCubit` ya lee las fuentes en cada recarga, y las expone en el estado como un mapa `sourceId → iconUrl`.
- Sin cambios en el llamado a la acción ("Leer →" / "Abierto"), el swipe de descarte, la accesibilidad, el conteo ni los textos: no hay claves de l10n nuevas.

Fuera de alcance: un CTA tipo botón pastilla (se descartó; el CTA queda como está).

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `inbox-daily-summary-card`: el requirement "Contenido y aspecto de la tarjeta" cambia en los avatares (ícono real con fallback a inicial), el ícono de destello y el radio.

## Impact

- Código: `lib/features/inbox/presentation/widgets/inbox_summary_card.dart`, `lib/features/inbox/presentation/cubit/inbox_cubit.dart` y `inbox_state.dart`, y `lib/features/inbox/presentation/screens/inbox_screen.dart` (pasa el mapa a la tarjeta).
- Reutiliza `CachedNetworkImageWidget` (`core/widgets/`); no importa entre features ni agrega use cases.
- Sin cambios de servidor, de modelo, de sincronización ni de l10n.
- Tests: `inbox_summary_card_test.dart`, `inbox_cubit_test.dart` y `inbox_screen_summary_card_test.dart`.
- iPad: la tarjeta ya vive en la columna central del master-detail; el tamaño y el layout de la fila no cambian de forma relevante, y el estado seleccionado (borde de 2px, "Abierto") se conserva.
