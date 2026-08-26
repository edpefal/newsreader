## 1. Breakpoint compartido y `AdaptiveShell` (rail vs. drawer)

- [x] 1.1 Crear utilidad de breakpoint (ej. `core/utils/window_size_class.dart`) que exponga si el ancho actual es "compact" (<840dp) o "expanded" (≥840dp) a partir de `MediaQuery.sizeOf(context).width`
- [x] 1.2 Crear `AdaptiveShell` en `lib/presentation/app/adaptive_shell.dart` que renderice `NavigationRail` + `Scaffold` sin drawer en modo expanded, y el `NavigationDrawer` actual en modo compact (se dejó fuera de `core/widgets/` porque depende de Cubits de features, ver design.md)
- [x] 1.3 Migrar los 5 destinos (Inbox con badge, Favoritos, Archivo, Fuentes, Resúmenes) al `NavigationRail`, reusando los mismos íconos/labels/lógica de búsqueda que hoy vive en `_ScaffoldWithNavBar`
- [x] 1.4 Agregar el ícono de Ajustes fijo al pie del `NavigationRail`, navegando a `/settings`
- [x] 1.5 Reemplazar `_ScaffoldWithNavBar` en `router.dart` por `AdaptiveShell` como builder del `StatefulShellRoute.indexedStack`
- [x] 1.6 Al cruzar el umbral de 840dp se alterna entre rail y drawer sin perder la tab seleccionada — verificado manualmente en simulador por el usuario (no automatizado: requeriría levantar un `StatefulShellRoute` completo en el harness de test; la lógica del breakpoint sí está cubierta por `window_size_class_test.dart`)

## 2. Mover "Cerrar sesión" a Ajustes

- [x] 2.1 Agregar la acción "Cerrar sesión" (incluyendo el flujo de `ClearLocalUserData` + `AuthClient.signOut()` que hoy vive en `router.dart`) dentro de `SettingsScreen`
- [x] 2.2 Quitar el `ListTile` de "Cerrar sesión" del `NavigationDrawer`/`AdaptiveShell`
- [x] 2.3 Crear widget test de `SettingsScreen` cubriendo la acción de cerrar sesión (`settings_screen_test.dart`)
- [x] 2.4 N/A — no existía ningún widget test previo del Drawer que referenciara "Cerrar sesión" (se confirmó por grep antes de implementar)

## 3. `AdaptiveListDetailScaffold` genérico

- [x] 3.1 Crear `AdaptiveListDetailScaffold` en `core/widgets/` que reciba `list` y `detail` (el `child` de un `ShellRoute`) y renderice el layout de dos paneles (usado solo en modo expanded; en modo compact el `ShellRoute` de la branch devuelve `child` directamente, ver design.md Decisión 4)
- [x] 3.2 Crear el widget compartido `EmptyDetailPlaceholder` (icono + texto localizado) para el panel derecho sin selección
- [x] 3.3 Test widget del scaffold genérico: en modo expanded muestra lista + detalle simultáneamente; verifica que el ancho del panel de lista es estable

## 4. Reestructurar rutas de detalle como sub-rutas anidadas por branch

- [x] 4.1 Reemplazar la ruta compartida top-level `/article/:id` (y `/article/:id/web`) por sub-rutas anidadas propias de Inbox (`/article/:id`) y Archivo (`/archive/article/:id`); actualizar `inbox_screen.dart` y `archive_screen.dart` para navegar a su propia sub-ruta
- [x] 4.2 Agregar la sub-ruta anidada de Favoritos (`/favorites/article/:id`) dentro de su branch; actualizar `favorites_screen.dart` para navegar a ella
- [x] 4.3 Mover `/sources/:id` a sub-ruta anidada dentro del branch de Fuentes, y agregar la sub-ruta anidada del artículo bajo ella (`/sources/:id/article/:articleId`); actualizar `source_detail_screen.dart` para navegar a esa sub-ruta en vez de a `/article/:id`
- [x] 4.4 Mover `/summaries/:date` a sub-ruta anidada dentro del branch de Resúmenes, y agregar la sub-ruta anidada del artículo bajo ella (`/summaries/:date/article/:articleId`); actualizar `summary_detail_screen.dart` para navegar a esa sub-ruta
- [x] 4.5 Verificar que `RouteExtraResolver` y los tests de la capability `route-state-recovery` siguen funcionando igual (resolución por id, redirect a Inbox si no existe, loading intermedio) con las rutas anidadas — suite completa corrida, sin regresiones
- [x] 4.6 La app no tiene URL scheme propio ni universal links configurados (`Info.plist` solo registra el scheme reverso de Google Sign-In) — no hay una puerta de entrada externa real para probar un "deep link" desde afuera. Lo que esta tarea buscaba verificar (resolver una ruta de detalle sin el objeto en memoria, en modo split vs. compact) ya está cubierto por los tests automatizados de la capability `route-state-recovery` (`RouteExtraResolver`), que pasan en la suite completa.

## 5. Split view en Inbox, Favoritos y Archivo

- [x] 5.1 Adaptar Inbox para usar `AdaptiveListDetailScaffold` vía `ShellRoute` de su branch: lista a la izquierda, `ReaderScreen` del artículo seleccionado (o `EmptyDetailPlaceholder`) a la derecha en modo expanded
- [x] 5.2 Repetir para Favoritos y Archivo (misma factory `articleListBranch` en `router.dart`)
- [x] 5.3 Crear el estado vacío "selecciona un artículo" para el panel derecho (`EmptyDetailPlaceholder`, reusado por las 3 tabs)
- [x] 5.4 El swipe-to-read de la lista no se tocó (sigue en `InboxScreen`/`FavoritesScreen`/`ArchiveScreen` sin cambios de lógica); confirmado sin regresiones por la suite completa
- [x] 5.5 Selección independiente por tab — verificado manualmente en simulador por el usuario (no automatizado: requeriría un harness con `StatefulShellRoute` completo; la persistencia se apoya en que `StatefulShellBranch` ya preserva el `Navigator`/estado de cada rama, comportamiento nativo de go_router, no código nuevo)

## 6. Split view en Fuentes (con sub-stack en el panel derecho)

- [x] 6.1 Adaptar Fuentes para usar `AdaptiveListDetailScaffold`: lista de fuentes a la izquierda, `SourceDetailScreen` de la fuente seleccionada (o `EmptyDetailPlaceholder`) a la derecha en modo expanded
- [x] 6.2 Dentro del panel derecho de Fuentes, tocar un artículo de `SourceDetailScreen` reemplaza el panel por `ReaderScreen` (misma `ShellRoute`/`Navigator` de la branch, un nivel más anidado)
- [x] 6.3 El control de "volver" es el `BackButton` que `ReaderScreen` ya trae en su AppBar (`context.pop()` sobre el `Navigator` de la branch) — no hizo falta agregar UI nueva
- [x] 6.4 Seleccionar fuente → abrir artículo de esa fuente → volver, sin perder la lista de fuentes ni la fuente seleccionada — verificado manualmente en simulador por el usuario, incluyendo seleccionar una fuente distinta con un artículo aún abierto (no automatizado: requeriría el mismo harness de `StatefulShellRoute` completo)

## 7. Split view en Resúmenes

- [x] 7.1 Adaptar Resúmenes para usar `AdaptiveListDetailScaffold`: lista de resúmenes a la izquierda, `SummaryDetailScreen` del resumen seleccionado (o `EmptyDetailPlaceholder`) a la derecha en modo expanded
- [ ] 7.2 Verificación manual de selección/estado vacío en Resúmenes — pendiente a propósito: requiere datos de PROD (generación de resúmenes) para probarse, el usuario la deja explícitamente pendiente para una sesión futura. No automatizado tampoco (mismo motivo que 5.5/6.4).

## 8. Preservar selección al cruzar el breakpoint

- [x] 8.1 No hizo falta implementar re-navegación manual (ver design.md Decisión 4/5, actualizada durante `/opsx:apply`): al usar `ShellRoute` por branch, el mismo `Navigator` interno se reutiliza sin importar si se renderiza a pantalla completa o dentro del panel derecho — Flutter preserva su estado por `GlobalKey` al moverlo de posición en el árbol
- [x] 8.2 El scroll de `ReaderScreen` depende de su propio `ScrollController`, atado al ciclo de vida del `State` del widget, que se preserva por el mecanismo anterior (no depende de si el contenedor es panel o pantalla completa)
- [x] 8.3 Ítem seleccionado en modo expanded → resize a compact (y viceversa) conserva el mismo ítem con el scroll — verificado manualmente en simulador por el usuario (no automatizado: requeriría simular resize de ventana sobre un `StatefulShellRoute` real)

## 9. Ancho máximo del lector (~680pt)

- [x] 9.1 Envolver el cuerpo de `ReaderScreen` (título, metadata, HTML) en `ConstrainedBox`/`Center` (`_MaxWidthCentered`, `kReaderMaxContentWidth = 680`), aplicado tanto en modo split como en pantalla completa
- [x] 9.2 El contenido raw de email queda exento: `_isRawEmailArticle` (usa `looksLikeRawEmailHtml`, ahora pública para este consumo) evita envolver el `WebView` aislado en el `ConstrainedBox`
- [x] 9.3 Test widget: ancho disponible mayor a 680pt centra el contenido (`renderedSize.width <= 680`); ancho menor a 680pt ocupa todo el espacio disponible (`reader_screen_test.dart`)

## 11. Fixes post-verificación manual del usuario en simulador

- [x] 11.1 Bug: en modo split, seleccionar un segundo artículo sin volver del primero rompía la ruta (`GoException: no routes for location: /archive/article/<id1>/article/<id2>`) — causa: `GoRouterState.of(context)` no es confiable dentro del panel de lista de un `ShellRoute` (ver design.md, sección de Risks). Fix: Inbox/Favoritos/Archivo navegan con paths literales fijos en vez de derivarlos de `GoRouterState.of(context)`.
- [x] 11.2 Bug: en modo split, los artículos leídos solo se archivaban (animación de salida) al tocar el chevron de volver, no al abrir un segundo artículo directamente — causa: `context.push` apilaba páginas indefinidamente ya que en split nunca hay un "volver" real que resuelva el `Future` del push. Fix: nuevo helper `openDetailRoute` (`core/navigation/route_path.dart`) que en modo expanded usa `context.go` (reemplaza en vez de apilar) y dispara la acción post-navegación de inmediato; aplicado en Inbox (con `InboxCubit.markAsRead`, reusando el método existente del swipe-to-read), Favoritos, Archivo, Fuentes y Resúmenes.
- [x] 11.3 UX: la pantalla de Ajustes no estaba adaptada a pantallas anchas (contenido pegado a la izquierda, con mucho espacio vacío a la derecha). Fix: mismo criterio que el lector — `ConstrainedBox(maxWidth: 680)` centrado (`kSettingsMaxContentWidth`), alineado arriba.
- [x] 11.4 UX: `LoginScreen` usaba `crossAxisAlignment.stretch`, estirando los botones de Google/Apple al ancho completo de la pantalla. Fix: `ConstrainedBox(maxWidth: 400)` centrado (`kLoginMaxContentWidth`).
- [x] 11.5 Bug: al rotar el dispositivo con un artículo del Inbox ya leído (en modo split, vía `markAsRead`), la columna de lista aparecía vacía ("You're all caught up") aunque sí hubiera artículos no leídos — tanto al pasar de portrait→landscape como de landscape→portrait y volver con el chevron. Causa: `InboxCubit` deja `readArticleId` seteado en su último estado emitido indefinidamente (es solo una señal transitoria para animar la salida, no significa que la lista esté desactualizada); `InboxView._InboxViewState.didChangeDependencies` solo poblaba `_flatItems` inicial cuando `readArticleId == null`. Al rotar, `InboxView` se remonta (cambia de posición en el árbol entre panel único y panel dividido) y arrancaba con `_flatItems` vacía si ese flag seguía seteado. Fix: poblar `_flatItems` desde `state.visibleArticles` siempre que el estado sea `InboxLoaded`, sin condicionar a `readArticleId` (los datos ya vienen filtrados por `_reload`).
- [x] 11.6 Tests nuevos cubriendo los cinco fixes: selección en modo split de Inbox (`inbox_screen_test.dart`), remount de Inbox con `readArticleId` heredado (`inbox_screen_test.dart`), rutas corregidas de Archivo/Favoritos (`archive_screen_test.dart`, `favorites_screen_test.dart`), ancho máximo de Ajustes (`settings_screen_test.dart`) y de Login (`login_screen_test.dart`)
- [x] 11.7 Búsqueda (ícono de lupa en el `NavigationRail`) verificada manualmente en simulador en modo split — funciona sin ajustes adicionales
- [x] 11.8 Rotar con Favoritos/Archivo abiertos (sin artículo seleccionado o con uno abierto) verificado manualmente en simulador — sin el bug del Inbox, como se esperaba (esas pantallas no usan `readArticleId`)
- [x] 11.9 Rotar con el WebView del artículo abierto (`/article/:id/web`) verificado manualmente en simulador — sin problemas
- [x] 11.10 Bug: en iPhone landscape (pantalla mucho más baja que un iPad), el `NavigationRail` se desbordaba verticalmente ("BOTTOM OVERFLOWED") porque las 5 destinations + el ícono de Ajustes no entraban en el alto disponible y `NavigationRail` no hace scroll interno. Fix: `_AdaptiveNavigationRail` envuelve el rail en `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight)` + `IntrinsicHeight`, para que scrollee en vez de desbordar cuando no entra.
- [x] 11.11 Decisión de producto (a pedido del usuario, no un bug): bloquear el iPhone a portrait-only, dejando el iPad con las 4 orientaciones. Se resuelve enteramente en `ios/Runner/Info.plist` (la clave `UISupportedInterfaceOrientations`, específica de iPhone, ya no incluye landscape; `UISupportedInterfaceOrientations~ipad` queda sin cambios) — sin código Dart, ya que iOS diferencia por idiom de dispositivo a nivel de plist. Como consecuencia, el iPhone ya no puede cruzar el breakpoint de 840dp por rotación (11.10 queda como refuerzo, no como requisito para este caso).

## 10. Validación final

- [x] 10.1 `flutter analyze` sin warnings
- [x] 10.2 `flutter test` completo: 459/460 tests pasan; el único fallo (`localized_date_formatter_test.dart` - hora de un dígito sin cero a la izquierda) es preexistente y no relacionado a este change
- [x] 10.3 Tests nuevos para las capabilities `adaptive-navigation-rail` (parcial: breakpoint) y `adaptive-master-detail` (`AdaptiveListDetailScaffold`, `EmptyDetailPlaceholder`); los escenarios de integración completa (rail↔drawer visual, selección cruzando tabs/breakpoint, sub-stack de Fuentes) quedan para verificación manual en simulador, siguiendo la convención del proyecto
