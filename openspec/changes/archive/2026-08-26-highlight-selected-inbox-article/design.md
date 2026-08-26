## Context

Hoy, `InboxView` (`lib/features/inbox/presentation/screens/inbox_screen.dart`) maneja el modo expandido así: al tocar un artículo, navega con `context.go('/article/:id')` y llama `cubit.markAsRead(article.id)`, que ejecuta `MarkArticleAsRead` y recarga (`_reload(readArticleId: id)`). `InboxState.readArticleId` es una señal transitoria: `BlocConsumer.listener` la detecta y dispara `_animateDismiss`, que anima la salida del artículo de la `AnimatedList` (ya no está en `articles` porque el repositorio excluye los leídos).

`ReaderScreen` (`lib/features/reader/presentation/screens/reader_screen.dart`) ya llama a `widget.markAsRead.execute(article.id)` en su propio `initState`, independientemente de quién lo abrió. Es decir, el dato `isRead=true` ya queda persistido apenas se abre el lector; la llamada duplicada de `InboxCubit.markAsRead` en el tap del modo expandido solo existe para disparar el reload que hace desaparecer la fila.

El `ShellRoute` de la branch de Inbox (`lib/presentation/app/router.dart`, `articleListBranch`) usa `_articleListRoot` para decidir qué se muestra en la ruta raíz del panel derecho en modo expandido: hoy es siempre el mismo `EmptyDetailPlaceholder` genérico, compartido con Favoritos y Archivo.

## Goals / Non-Goals

**Goals:**
- Desacoplar "el artículo está marcado como leído" (dato persistido, sin cambios) de "el artículo desaparece de la lista visible del Inbox" (ahora depende de si sigue siendo la selección abierta).
- Reusar la animación de salida ya existente (`_animateDismiss` + `readArticleId`) para el momento en que el artículo sí se archiva.
- Mantener el comportamiento intacto en modo compacto y en Favoritos/Archivo/Fuentes/Resúmenes.

**Non-Goals:**
- No cambia cuándo se persiste `isRead=true` (sigue siendo al abrir, vía `ReaderScreen`).
- No introduce un estado "pendiente de leer" ni un mecanismo de deshacer.
- No toca el layout de Favoritos ni Archivo (no tienen esta mecánica de auto-marcado al abrir en primer lugar).

## Decisions

### 1. Nuevo campo persistente `openArticleId` en `InboxLoaded`, separado de `readArticleId`
`readArticleId` sigue siendo la señal transitoria de "animar la salida de este artículo ahora". Se agrega `openArticleId`, que representa la selección actualmente resaltada (o `null` si ninguna). Mantenerlos separados evita pisar la semántica que ya usa `_animateDismiss`/`buildWhen` en `InboxView`.

Alternativa descartada: reusar `readArticleId` para ambos fines. Se descarta porque su semántica actual es "acabo de leer esto, animá su salida una vez", y forzarlo a persistir como selección abierta rompería el `buildWhen`/`listenWhen` existentes (que asumen que se limpia después de cada emisión relevante).

### 2. El tap en modo expandido deja de llamar a `markAsRead`; llama a un nuevo método `selectArticle`
`InboxCubit.selectArticle(String id)`:
- Si no había ningún artículo abierto (`openArticleId == null`), solo emite `InboxLoaded` con `openArticleId: id` (sin reload; los datos de `articles` no cambiaron).
- Si había un artículo abierto distinto, dispara `_reload(readArticleId: previousId, openArticleId: id)`: la recarga ya no incluye al anterior (el repositorio filtra por `isRead`, y `ReaderScreen` ya lo marcó leído al abrirse originalmente), por lo que `_animateDismiss` lo anima hacia afuera igual que hoy, y el nuevo `openArticleId` queda resaltado.
- Si se toca el mismo artículo que ya está abierto, no hace nada.

`ArticleInboxTile` recibe un nuevo parámetro `isOpen: bool` (o similar) para pintar el fondo resaltado cuando `article.id == openArticleId`.

### 3. Cierre explícito vía el estado vacío del panel derecho
Se necesita un punto donde detectar "el usuario volvió y ya no hay ningún artículo abierto en el panel derecho del Inbox". Ese punto es cuando la ruta raíz de la branch de Inbox vuelve a construirse en modo expandido (`_articleListRoot` mostrando `EmptyDetailPlaceholder`) — ocurre exactamente al tocar el botón de volver del lector, porque go_router hace pop hasta la raíz de esa branch.

Se agrega un widget pequeño (p. ej. `_InboxEmptyDetail`, stateful) que en su `initState` llama a `context.read<InboxCubit>().closeOpenArticle()`. Este método hace `_reload(readArticleId: current.openArticleId)` si había uno abierto (dejando `openArticleId` en `null` vía el `_reload` por defecto), reusando otra vez la animación de salida existente. Solo se instancia para la branch de Inbox (Favoritos/Archivo no tienen `openArticleId`, así que `_articleListRoot` genérico sigue sirviendo para ellas sin cambios).

Alternativa descartada: usar un `NavigatorObserver` global para detectar el pop de `/article/:id` a `/`. Se descarta por ser más invasivo (afecta a las 5 branches) para resolver algo que ya tiene un punto de extensión natural (`_articleListRoot`).

### 4. Color del resaltado: `colorScheme.secondaryContainer`
`AppTheme` (`lib/presentation/theme/app_theme.dart`) ya remapea `secondaryContainer` a un tinte sutil (`_hairline` en light, `_darkHairline` en dark) específicamente para el indicador de selección del `NavigationDrawer`/`NavigationRail` — ya está calibrado para leerse bien como "selección" en ambos temas sin competir con el resto de la UI. Se reusa ese mismo token para el fondo de la fila resaltada del Inbox, en vez de introducir un color nuevo.

## Risks / Trade-offs

- [Riesgo] Si el usuario nunca cierra el artículo (nunca vuelve ni selecciona otro) y sale de la app, `isRead` ya quedó en `true` (por `ReaderScreen`) pero la fila sigue apareciendo en el Inbox resaltada en la próxima sesión hasta que se cierre. → Aceptable: es exactamente el comportamiento pedido (visible mientras "abierto"); al volver a abrir la app, `openArticleId` no persiste entre sesiones (vive solo en el estado en memoria del cubit), así que el artículo simplemente aparece como leído-pero-visible una vez y se resuelve con la primera interacción (tocar otro artículo o, si se reabre esa branch, el `_articleListRoot` inicial no dispara `closeOpenArticle` porque no hubo `openArticleId` en la nueva sesión del cubit — el artículo pasa a comportarse como cualquier leído y desaparece en el próximo `_reload` natural, p. ej. `loadArticles()` al iniciar).
- [Riesgo] Doble reload en sucesión rápida si el usuario togglea artículos muy rápido. → Ya existe hoy el mismo patrón (`markAsRead` + `_reload` por cada tap); no se introduce un caso nuevo de carrera.

## Migration Plan

Cambio de UI/estado puramente aditivo sobre un flujo existente; no requiere migración de datos (no cambia el modelo `Article` ni Hive). Se despliega como cualquier otro cambio de la app.
