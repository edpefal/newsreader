## Why

El resumen diario solo es accesible desde la tab "Resúmenes" del menú lateral, así que pasa desapercibido para quien nunca entra ahí. Hay que ponerlo donde el usuario ya mira todos los días -- la parte superior del Inbox -- como un ítem temporal que desaparece una vez atendido, al estilo de la sección "Your DJ Mix" de Snipd.

## What Changes

- El Inbox muestra una **tarjeta destacada** del resumen diario de hoy (fecha local) como primer elemento del scroll, justo debajo del AppBar/buscador. No participa del filtro de búsqueda ni de la lista animada de artículos.
- La tarjeta es sólida con el acento óxido de marca (`ReevoAccent`, referenciado de forma explícita), muestra el conteo de artículos y hasta 3 avatares de las fuentes incluidas más un `+N` (desde `sourceBlocks`), con fallback a una versión mínima cuando `sourceBlocks` es `null`. Es accesible: etiqueta semántica única y acción "Descartar" para lectores de pantalla.
- El Inbox pasa de `AnimatedList` a `CustomScrollView` + `SliverAnimatedList` para que la tarjeta scrollee con la lista (también con el Inbox vacío y con pull-to-refresh).
- "Hoy" se calcula comparando `date.toLocal()` con la fecha local, para que funcione con husos al este de UTC (el índice de Hive por `dateKey` en UTC no sirve para eso).
- La tarjeta se quita del Inbox al **abrir el detalle del resumen de hoy, desde donde sea** (la tarjeta o la tab Resúmenes) o al **descartarla con swipe** (`endToStart`, sin deshacer). Ambas acciones persisten `dismissed_at` en el `DailySummary`, con **push inmediato** best-effort a Supabase y sincronizado con el resto de dispositivos.
- El `InboxCubit` se suscribe a un `Stream` de resúmenes (respaldado por `box.watch()` de Hive, dentro del datasource) para reaccionar a cambios hechos en otra tab o traídos por sync.
- Solo el resumen de hoy vive en el Inbox: un resumen anterior no abierto ni descartado se reemplaza por el nuevo y queda únicamente en la tab Resúmenes. La tab Resúmenes sigue mostrando todos, descartados o no.
- Ruta nueva `/summary/:id` en la rama Inbox que reutiliza `SummaryDetailScreen`: pantalla completa por debajo de 840dp, panel derecho en el layout de dos paneles. En iPad la tarjeta permanece visible y resaltada mientras su detalle está abierto, y sale al cerrarlo.
- En iPad la tarjeta se resalta con un borde de 2px en el color del texto y el CTA pasa a "Abierto", mientras la ruta activa esté bajo `/summary/:id/**` (el resumen o un artículo abierto desde él).
- Dos eventos de producto: `inbox_summary_card_opened` e `inbox_summary_card_dismissed` (propiedad `article_count`), emitidos solo por acciones del usuario sobre la tarjeta (no al abrir el resumen desde la tab ni por un `dismissed_at` recibido vía sync).
- Reporte a Sentry de las fallas nuevas (carga del resumen pendiente, persistencia de `dismissed_at`, resumen inexistente al abrir), siguiendo el requirement existente de `observability`.
- Columna nueva `daily_summaries.dismissed_at timestamptz null` (migración retrocompatible con clientes ya publicados).

## Capabilities

### New Capabilities
- `inbox-daily-summary-card`: tarjeta temporal del resumen diario en el Inbox -- elegibilidad (resumen de hoy sin descartar), contenido, apertura, descarte con swipe, reemplazo diario y comportamiento con buscador vacío/activo.

### Modified Capabilities
- `cloud-sync`: `daily_summaries` incluye `dismissed_at`; se sube con push inmediato best-effort y con el sync completo, se baja con el resto del resumen, sin pisar un valor local con un remoto vacío y sin que un cliente anterior que no lo envía lo borre.
- `adaptive-master-detail`: el detalle de un resumen abierto desde el Inbox se muestra en el panel derecho del Inbox, con la tarjeta resaltada mientras está abierto.
- `product-analytics`: se suman los eventos de la tarjeta a las acciones instrumentadas y se aclara que no contradicen la exclusión del evento de "ver un resumen".

## Impact

- **Servidor:** migración `add_daily_summaries_dismissed_at` en Supabase. Debe aplicarse **antes** de publicar el cliente nuevo (si no, el upsert de `daily_summaries` falla por columna inexistente). Confirmar con el usuario si se aplica a `reevo-dev`, `reevo` o ambos. Es aditiva y no rompe a los clientes 1.8.x.
- **Datos locales:** `DailySummaryModel` gana `@HiveField(7) dismissedAt` (regenerar con `build_runner`).
- **Código:** `SyncUserData`, `SummaryRepository` y su datasource (incluido un `Stream`), `SummaryDetailScreen` (callback `onOpened`), `InboxCubit`/`InboxState`, `InboxScreen` (refactor a slivers), un widget de tarjeta nuevo, `router.dart`, `injection.dart`, 3 archivos `.arb`.
- **Documentación del proyecto:** `CLAUDE.md` gana la sección "Offline-first con push inmediato" (ya agregada en esta rama).
- **Fuera de alcance:** generación del resumen en el servidor, elegibilidad por suscripción, y la tab Resúmenes.
