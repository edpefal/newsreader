## 1. Servidor

- [x] 1.1 Crear la migración `supabase/migrations/<timestamp>_add_daily_summaries_dismissed_at.sql` con `alter table daily_summaries add column if not exists dismissed_at timestamptz` (nullable, sin default)
- [x] 1.2 Confirmar con el usuario a cuál(es) proyecto(s) aplicarla (`reevo-dev` y/o `reevo`) y aplicarla con `apply_migration` ANTES de publicar el cliente; verificar con `list_tables`/`execute_sql` que la columna existe
- [x] 1.3 Verificar en `reevo-dev` que un upsert sin `dismissed_at` (cliente anterior) no borra un valor ya existente, y que `updatePartial` solo toca `dismissed_at` y `updated_at`

## 2. Modelo, repositorio y sincronización

- [x] 2.1 Agregar `dismissedAt` a `DailySummary` (entidad, `props`) y `@HiveField(7) DateTime? dismissedAt` a `DailySummaryModel`; regenerar con `dart run build_runner build --delete-conflicting-outputs`
- [x] 2.2 `SummaryLocalDataSource`/`HiveSummaryDatasource`: método para marcar un resumen como descartado (idempotente) que setea `dismissedAt` y `updatedAt` a `now`; `applyRemote` conserva el `dismissedAt` local cuando el remoto llega `null`; `Stream` de cambios respaldado por `box.watch()`
- [x] 2.3 `SummaryRepository`/`SummaryRepositoryImpl`: exponer `dismiss(id)` y `watchAll()`, y el mapeo de `dismissedAt` en ambos sentidos
- [x] 2.4 `SyncUserData`: incluir `dismissed_at` en `_summaryToRow` y leerlo en `_summaryFromRow`
- [x] 2.5 Push inmediato: tras escribir `dismissed_at` en Hive, `updatePartial('daily_summaries', [...])` best-effort, sin bloquear, ignorando fallas y solo con sesión activa (mismo patrón que `MarkArticleAsRead`)
- [x] 2.6 Tests unitarios: datasource (dismiss idempotente, `updatedAt` actualizado, `applyRemote` conserva el valor local, el `Stream` emite ante cambios), mapeo de sync subir/bajar, push inmediato (con conexión, sin conexión, sin sesión, falla ignorada)

## 3. Casos de uso e Inbox

- [x] 3.1 `features/inbox/domain/usecases/GetPendingInboxSummary`: resumen cuya `date.toLocal()` (solo fecha) es la fecha local de hoy y sin `dismissedAt`; NO usar `getByDate`. Test con usuario UTC+2 (fecha almacenada 22:00Z del día anterior) y UTC-6
- [x] 3.2 `DismissDailySummary`: descarta solo el resumen de hoy, idempotente, con push inmediato; ignora resúmenes de días anteriores; registrar ambos casos de uso en `core/di/injection.dart`
- [x] 3.3 `InboxCubit`/`InboxState`: `pendingSummary` y `openSummaryId`; suscripción al `Stream` (cancelada en `close()`); `dismissSummary` (swipe), `openSummary`, y limpieza de `openSummaryId` al volver al estado vacío (reutilizar `closeOpenArticle`/`onEmptyDetailShown`); `openSummaryId` se mantiene bajo `/summary/:id/**`; `openArticleId` y `openSummaryId` mutuamente excluyentes
- [x] 3.4 Eventos `inbox_summary_card_opened` / `inbox_summary_card_dismissed` con `article_count`, solo desde el tap y el swipe de la tarjeta (ni al abrir desde la tab ni por sync)
- [x] 3.5 `captureException` con contexto `{operation}` (sin contenido) en carga, suscripción y descarte; `sourceBlocks == null` no se reporta
- [x] 3.6 Tests de `InboxCubit` con `bloc_test` y mocktail: tarjeta presente/ausente, resumen de ayer ignorado, abrir (compacto) quita la tarjeta, abrir (expandido) la conserva hasta cerrar, conserva la selección bajo la ruta anidada de artículo, swipe, eventos una sola vez y ninguno por sync/tab, cambios por `Stream` (descarte externo, resumen que llega), `captureException` ante fallas con el Inbox funcionando

## 4. Refactor de la lista del Inbox

- [x] 4.1 Antes de mover nada, asegurar tests de los comportamientos existentes de `InboxScreen`: swipe de artículo, animación de salida al abrir, resaltado `openArticleId`, separadores de fecha, estado vacío, pull-to-refresh
- [x] 4.2 Pasar `AnimatedList` a `RefreshIndicator > CustomScrollView` con `SliverAnimatedList` (artículos y separadores) y un sliver superior para la tarjeta; adaptar `_listKey` y la lógica de `_flatItems`
- [x] 4.3 La rama de lista vacía aloja la tarjeta y el estado vacío dentro del mismo scroll con pull-to-refresh
- [x] 4.4 Verificar que los tests de 4.1 siguen en verde

## 5. Presentación de la tarjeta

- [x] 5.1 Widget `InboxSummaryCard` en `features/inbox/presentation/widgets/`: relleno `ReevoAccent` (referenciado explícitamente), texto de mayor contraste por tema, título, conteo de artículos/fuentes, hasta 3 avatares + `+N`, CTA "Leer"; fallback mínimo sin `sourceBlocks`; `const` donde se pueda
- [x] 5.2 Estado seleccionado: borde de 2px en `onSurface` con margen, y CTA "Abierto"; sin colores nuevos
- [x] 5.3 `Dismissible(endToStart)` con fondo propio distinto del teal de "leído" e ícono de cerrar; sin deshacer
- [x] 5.4 Accesibilidad: etiqueta semántica única, acción semántica "Descartar", estado seleccionado anunciado
- [x] 5.5 Textos en los 3 `.arb` (en/es/fr, español neutro con tuteo): `inboxSummaryCardTitle`, `…Cta`, `…Open`, `…Dismiss`, `…CountOnly` (plural de artículos) y `…Sources` (plural de fuentes; gen-l10n no admite dos plurales en un mensaje, así que el widget las une con " · "); francés con texto real; `flutter gen-l10n`
- [x] 5.6 Animación de entrada/salida de la tarjeta en `InboxScreen`
- [x] 5.7 Widget tests: la tarjeta no se filtra con el buscador, se muestra con Inbox vacío, swipe `endToStart` descarta y la otra dirección no, tap despacha la acción, fallback sin avatares, estado seleccionado

## 6. Navegación y detalle

- [x] 6.1 `SummaryDetailScreen`: callback `onOpened` por constructor, invocado una vez al mostrarse
- [x] 6.2 Conectar `onOpened` a `DismissDailySummary` en `/summaries/:id` y en la ruta nueva
- [x] 6.3 Ruta `/summary/:id` en la rama Inbox (`articleListBranch`) con `RouteExtraResolver` + `SummaryDetailScreen` y ruta anidada de artículo; `onNotFound` reporta `captureMessage` `warning` y redirige a `/`
- [x] 6.4 Confirmar que el detalle se muestra en el panel derecho del Inbox igual que en el de Resúmenes y que el back regresa al Inbox
- [x] 6.5 Razonar y verificar el layout ≥840dp: rail sigue en Inbox, la tarjeta se mantiene seleccionada con el detalle (o un artículo desde él) abierto, sale al volver al estado vacío, y la selección sobrevive al cruzar el breakpoint

## 7. Cierre

- [x] 7.1 `flutter analyze` sin warnings y `flutter test` en verde
- [x] 7.2 Validar con `openspec validate add-inbox-daily-summary-card --strict`
- [ ] 7.3 Pruebas manuales en simulador/dispositivo e iPad a cargo del usuario (tarjeta en claro/oscuro, swipe, apertura desde la tarjeta y desde la tab, sync entre dispositivos, rotación en iPad, usuario con huso al este de UTC)
- [ ] 7.4 Commits separados por cambio lógico (CLAUDE.md, migración, modelo/sync, Inbox, tarjeta), push de la rama, PR contra `main`, esperar `analyze-and-test` en verde y mergear; luego archivar el change en el mismo PR final y borrar la rama local y remota
