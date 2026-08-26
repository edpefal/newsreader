## Context

Ver `proposal.md` - Why para la motivación. Puntos técnicos relevantes ya confirmados en el código:

- `lib/presentation/app/router.dart` define un único `StatefulShellRoute.indexedStack` con 5 `StatefulShellBranch` (`/`, `/favorites`, `/archive`, `/sources`, `/summaries`) envueltos en `_ScaffoldWithNavBar`, que hoy siempre renderiza `NavigationDrawer`.
- Las rutas de detalle (`/article/:id`, `/article/:id/web`, `/sources/:id`, `/summaries/:date`) están declaradas **fuera** del shell, como `GoRoute` top-level independientes, cada una resolviendo su objeto de dominio vía `RouteExtraResolver` (capability `route-state-recovery`).
- No existe ningún breakpoint ni `MediaQuery`/`LayoutBuilder` usado para adaptar layout por tamaño en toda la capa de presentación.
- Cada tab ya tiene su propio Cubit singleton inyectado con `BlocProvider.value` en `app.dart`, y `StatefulShellBranch` ya preserva el estado de cada rama al cambiar de tab (usado hoy para no perder scroll de listas).

## Goals / Non-Goals

**Goals:**
- Un único punto de decisión de breakpoint (840dp) reutilizado tanto para rail vs. drawer como para split vs. push.
- Que las rutas de detalle sigan siendo direccionables por URL en ambos modos (compat con `route-state-recovery` y con deep links existentes).
- Que el cambio de modo (angosto ↔ ancho) sea transparente para los Cubits de cada feature: la selección vive en la capa de presentación de la tab, no en el Cubit de datos.

**Non-Goals:**
- No se rediseña la navegación de tres niveles a algo genérico y reusable para cualquier feature futura; el patrón de "panel derecho con stack propio" se resuelve puntualmente para Fuentes.
- No se agrega soporte de teclado/trackpad/Apple Pencil en este change.
- No se toca `SourceDetailScreen`/`SummaryDetailScreen` a nivel de contenido, solo su capacidad de embeberse en un panel.
- No se introduce un sistema de breakpoints multi-nivel (compact/medium/expanded/large); solo el umbral binario de 840dp pedido.

## Decisions

### 1. Breakpoint único basado en `MediaQuery.sizeOf(context).width`, no en orientación ni en `Platform.isIOS`
Se decidió no distinguir iPad de iPhone ni portrait de landscape explícitamente: la única señal es el ancho lógico de la ventana en dp, comparado contra 840. Esto cubre iPad en cualquier orientación, ventanas divididas de iPadOS (Split View/Slide Over), y iPhone grande en landscape, con una sola condición.
- Alternativa considerada: heurística por `Platform.isIOS && Theme.of(context).platform tablet`. Se descartó porque no reacciona a Split View/resize en vivo y no generaliza a Android tablets si la app llega a soportarlas.

### 2. Un solo widget de layout compartido: `AdaptiveShell` en `core/widgets/`
`_ScaffoldWithNavBar` se divide en dos responsabilidades: decidir el modo (rail/drawer, split/push) leyendo el ancho, y delegar el body a un widget por tab. Se introduce:
- `AdaptiveShell`: envuelve `NavigationRail`/`NavigationDrawer` según ancho, análogo al `_ScaffoldWithNavBar` actual pero parametrizado por breakpoint.
- `AdaptiveListDetailScaffold`: widget genérico reusado por las 5 tabs, recibe `listBuilder` y `detailBuilder` (o `emptyDetail`) y decide internamente si renderiza dos columnas (`Row`) o delega en un `Navigator`/push cuando el ancho es angosto.
- Alternativa considerada: usar el paquete `flutter_adaptive_scaffold` de Flutter. Se descarta para no sumar una dependencia nueva cuando el caso de uso (un solo breakpoint binario, 5 tabs con forma similar) es simple de resolver con un widget propio, consistente con que el proyecto no usa paquetes de UI de terceros salvo los ya presentes.

### 3. Selección modelada como la ubicación de la ruta anidada de la branch, no como estado separado
**Nota (ajustada durante `/opsx:apply`):** no hace falta un `ValueNotifier` propio para el "ítem seleccionado" de cada tab. Con el mecanismo de `ShellRoute` por branch de la Decisión 4, la selección **es** la ruta anidada actualmente activa dentro del `Navigator` de esa branch (ej. si el `Navigator` de Inbox está en `/article/abc123`, ese es el artículo seleccionado; si está en `/`, no hay selección). `StatefulShellBranch` ya persiste ese `Navigator` (y por lo tanto esa selección) al cambiar de tab. Los Cubits de datos (`InboxCubit`, `FavoritesCubit`, etc.) no necesitan saber nada de esto.
- Alternativa considerada: agregar `selectedArticleId` al estado de cada Cubit (`InboxLoaded`, `FavoritesLoaded`, etc.), o un `ValueNotifier` separado. Se descarta en ambos casos porque duplicaría una fuente de verdad que go_router ya mantiene (la ubicación de la ruta), con riesgo de que ambas queden desincronizadas.

### 4. Rutas de detalle siguen siendo `GoRoute` reales; el panel derecho las renderiza vía un `Navigator` anidado por tab (implementado con `ShellRoute` de go_router, no con estado manual)

**Nota (descubierta durante `/opsx:apply`, reemplaza la mecánica descripta originalmente en esta decisión):** en vez de "recrear" navegación manualmente al cruzar el breakpoint (como sugería la primera versión de esta decisión), cada branch usa un `ShellRoute` propio dentro de su `StatefulShellBranch`, con las rutas de detalle anidadas como hijas de la ruta raíz de esa branch:

```
StatefulShellBranch( // ej. Inbox
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        if (context.windowSizeClass == WindowSizeClass.compact) return child;
        return AdaptiveListDetailScaffold(list: const InboxListPane(), detail: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => context.windowSizeClass == WindowSizeClass.compact
              ? const InboxListPane()
              : const EmptyArticleDetailPlaceholder(),
          routes: [
            GoRoute(path: 'article/:id', builder: (context, state) => ReaderScreen(...)),
          ],
        ),
      ],
    ),
  ],
)
```

`child` en el `builder` de `ShellRoute` es el `Navigator` interno de esa branch ya resuelto a la página tope de su stack (con su propia animación de push/pop). Esto da, gratis:
- En modo compact, devolver `child` directamente reproduce el push a pantalla completa actual (la ruta raíz construye la lista; navegar a `article/:id` empuja el lector con la transición nativa de Flutter).
- En modo expanded, `child` se usa como panel derecho (mostrando el placeholder vacío o el lector, según la ruta activa) mientras el panel izquierdo se construye por separado, siempre visible, con la misma lista.
- La selección se preserva al cruzar el breakpoint sin ninguna lógica manual de re-navegación: es la misma ruta/Navigator (misma `GlobalKey<NavigatorState>` interna de go_router), solo movida de "ocupar toda la pantalla" a "ocupar el panel derecho" en el árbol de widgets. Flutter preserva el estado del `Navigator` (y por lo tanto el scroll del lector) al mover un widget con `GlobalKey` a otra posición del árbol.
- Para Fuentes y Resúmenes, el mismo mecanismo se anida un nivel más: `/sources/:id` y su `article/:articleId` son hijos de la misma ruta raíz del `ShellRoute` de esa branch, así que `child` sigue siendo "lo que esté en el tope del stack" sin importar la profundidad — el botón "volver" del lector (`context.pop()`) ya funciona porque opera sobre el `Navigator` de esa branch, sin UI adicional que construir.

Esto reemplaza la Decisión 5 original ("recrear el árbol de navegación re-navegando al mismo id"): no hace falta recrear nada, el `Navigator` de la branch nunca se destruye al cruzar el breakpoint, solo cambia su posición dentro del árbol de widgets.

Detalle original de la decisión (contexto de por qué la ruta deja de ser una única `/article/:id` compartida):
Para que un artículo conserve deep link y back button en modo split, cada tab en modo ancho mantiene su propio `Navigator` anidado dentro del panel derecho. Esto implica que `/article/:id` deja de ser una única ruta top-level compartida por 5 llamadores y pasa a declararse como sub-ruta anidada dentro de **cada** branch que lo necesita:
- Inbox: `/article/:id` (conserva el path actual, ya que Inbox vive en `/`).
- Favoritos: `/favorites/article/:id`.
- Archivo: `/archive/article/:id`.
- Fuentes: el artículo se abre desde dentro de `SourceDetailScreen`, ya en el panel derecho de la tab Fuentes; usa una sub-ruta anidada bajo `/sources/:id` (ej. `/sources/:id/article/:articleId`), con su propio `Navigator` para poder "volver" al detalle de la fuente sin salir del panel.
- Resúmenes: mismo criterio, sub-ruta anidada bajo `/summaries/:date` (ej. `/summaries/:date/article/:articleId`).

Cada llamador (`inbox_screen.dart`, `favorites_screen.dart`, `archive_screen.dart`, `source_detail_screen.dart`, `summary_detail_screen.dart`) navega a la sub-ruta correspondiente a su propio branch en lugar de al path compartido `/article/:id`. `AdaptiveListDetailScaffold` decide si el `Navigator` de esa sub-ruta ocupa toda la pantalla (modo push) o el panel derecho (modo split).
- Alternativa considerada y descartada: mantener un único `/article/:id` top-level. Técnicamente imposible de mostrar "al lado" del shell con `StatefulShellRoute` — una ruta top-level siempre reemplaza el shell completo (rail/lista incluidos), que es exactamente el comportamiento de push actual, no el split deseado.
- Alternativa considerada y descartada: eliminar la ruta real y modelar el panel derecho como estado de presentación sin URL propia. Se descarta por decisión explícita del usuario de mantener URLs reales por contexto aunque diverjan entre tabs.
- Trade-off aceptado: ya no existe una única URL canónica de artículo; cada contexto (Inbox/Favoritos/Archivo/Fuentes/Resúmenes) tiene la suya. No hay hoy ningún consumidor externo (push notifications, etc.) que dependa de `/article/:id` como URL universal — se verificó por grep que los únicos llamadores son las 5 pantallas ya mencionadas.

### 5. Transición de selección al cruzar el breakpoint
Ver Decisión 4: al usar `ShellRoute` por branch, cruzar el breakpoint no requiere ninguna lógica de re-navegación. El mismo `Navigator` interno de la branch (con el mismo `GlobalKey`) simplemente cambia de posición en el árbol de widgets (de "pantalla completa" a "panel derecho" o viceversa), y Flutter preserva su estado (incluyendo el scroll de `ReaderScreen`) al mover un widget con `GlobalKey`.
- Riesgo aceptado: un pequeño re-layout visual al cruzar el breakpoint durante un resize en vivo (ver Risks) — no hay pérdida de estado, solo un reacomodo de posición.

### 6. Ancho máximo del lector con `ConstrainedBox(maxWidth: 680)` centrado, a nivel de `ReaderScreen`, no del `HtmlContentRenderer`
El límite de ancho se aplica en `ReaderScreen` (envolviendo todo el cuerpo: título, metadata, HTML) y no dentro de `FwhHtmlContentRenderer`, para que título/fecha/fuente también respeten el mismo ancho de lectura cómoda, no solo el HTML.
- Alternativa considerada: aplicar el `maxWidth` solo al HTML. Se descarta porque dejaría el título/header del artículo a ancho completo mientras el cuerpo queda centrado y angosto, un layout inconsistente.

## Risks / Trade-offs

- **[Riesgo] Resize en vivo en iPad (Split View/Slide Over) reconstruye el `Navigator` de la tab activa, pudiendo perder animaciones en curso** → Mitigación: la reconstrucción solo ocurre al cruzar el umbral exacto de 840dp (no en cada pixel de resize), y se preserva el id seleccionado para que el usuario no perciba pérdida de contexto, solo un breve re-layout.
- **[Riesgo] Mover rutas de detalle de top-level a anidadas dentro de cada branch cambia cómo `RouteExtraResolver`/`route-state-recovery` reciben el `state.pathParameters`** → Mitigación: el contrato de `route-state-recovery` (resolver por id cuando falta el `extra`) no depende de la posición de la ruta en el árbol, solo del path param; se debe verificar con los tests existentes de esa capability tras el cambio.
- **[Riesgo] Cinco tabs implementando `AdaptiveListDetailScaffold` con formas de "detalle" distintas (lector simple vs. Fuentes con sub-stack) puede tentar a un widget genérico sobre-flexible** → Mitigación: `AdaptiveListDetailScaffold` solo resuelve el layout de dos columnas y el modo split/push; la lógica de "stack propio dentro del panel derecho" de Fuentes se resuelve con un `Navigator` anidado normal dentro de su `detailBuilder`, no con parámetros especiales del scaffold genérico.
- **[Trade-off] Se restringe el ancho de lectura también en iPhone landscape**, lo cual es explícito en la proposal pero vale notarlo como cambio de comportamiento visible incluso en teléfonos, no solo en iPad.
- **[Bug encontrado y corregido tras `/opsx:apply`, reportado por el usuario] en modo split, seleccionar un segundo artículo del Inbox sin volver al primero no disparaba la animación de archivado.** Causa: `context.push` apila páginas dentro del `Navigator` de la branch sin límite mientras la lista sigue visible (no hay "volver" en modo split); `loadArticlesAfterReading`/el swipe-dismiss dependían de que el `push` se resolviera (pop), algo que en modo split solo pasa si el usuario navega explícitamente hacia atrás. **Fix:** se agregó `openDetailRoute` (`core/navigation/route_path.dart`), que en modo expanded usa `context.go` (reemplaza la ruta activa del panel en vez de apilar) y dispara el callback post-navegación de inmediato en vez de esperar un pop que no va a ocurrir; en modo compact sigue usando `push` + esperar el pop, sin cambios de comportamiento. Para Inbox específicamente (único lugar con animación de salida al marcar leído), el tap en modo expanded llama directamente a `InboxCubit.markAsRead` (ya existente, reusado del swipe-to-read) en vez de depender de que `ReaderScreen` lo haga por su cuenta al abrirse.
- **[Bug encontrado y corregido tras `/opsx:apply`] `GoRouterState.of(context)` no es confiable dentro del panel de lista de `AdaptiveListDetailScaffold` en modo expanded.** Causa: como el `list` de Inbox/Favoritos/Archivo se construye directamente en el `builder` del `ShellRoute` (no a través de su propia `GoRoute`), no tiene un `ModalRoute`/`Page` propio — `GoRouterState.of(context)` termina resolviendo al `Page` que envuelve *todo* el `ShellRoute` (lista + panel derecho), cuyo estado registrado refleja la ruta anidada más profunda actualmente activa, no la raíz de la branch. Usar `GoRouterState.of(context).uri.path` para calcular la ruta del artículo tocado en la lista producía URLs incorrectas del tipo `/archive/article/<id1>/article/<id2>` al abrir un segundo artículo mientras el primero seguía en el panel derecho (reproducible solo en modo split, iPad). **Fix:** `inbox_screen.dart`, `favorites_screen.dart` y `archive_screen.dart` navegan con paths literales fijos (`/article/:id`, `/favorites/article/:id`, `/archive/article/:id`) en vez de derivarlos de `GoRouterState.of(context)`. Esta técnica de "path relativo a la ubicación actual" sigue siendo válida y se mantiene en `reader_screen.dart` (`_openWebView`), `source_detail_screen.dart` y `summary_detail_screen.dart`, porque esas pantallas SÍ se construyen siempre a través de su propia `GoRoute` anidada (con `Page` propio dentro del `Navigator` interno del `ShellRoute`), nunca como el panel de lista construido directamente por el shell.

## Migration Plan

- Cambio de presentación puro; no requiere migración de datos ni de esquema de Hive/Supabase.
- Se recomienda implementar en orden: (1) breakpoint + `AdaptiveShell` (rail/drawer) de forma aislada y verificable sin tocar rutas, (2) mover "Cerrar sesión" a Ajustes, (3) `AdaptiveListDetailScaffold` + reestructuración de rutas anidadas para Inbox/Favoritos/Archivo, (4) extender a Fuentes (con su sub-stack) y Resúmenes, (5) `maxWidth` del lector (independiente del resto, se puede hacer en paralelo).
- Sin flag de rollout: al ser una app con `flutter build`/App Store, el rollback es revertir el commit/release si aparecen regresiones.
