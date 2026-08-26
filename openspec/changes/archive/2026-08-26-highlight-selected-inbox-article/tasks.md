## 1. Estado del InboxCubit

- [x] 1.1 Agregar `openArticleId` a `InboxLoaded` (`inbox_state.dart`), incluido en `props`.
- [x] 1.2 Extender `InboxCubit._reload` para aceptar y propagar `openArticleId`.
- [x] 1.3 Implementar `InboxCubit.selectArticle(String id)`: no-op si ya es el abierto; solo emite `openArticleId` si no había uno previo; si había uno distinto, hace `_reload(readArticleId: previous, openArticleId: id)`.
- [x] 1.4 Implementar `InboxCubit.closeOpenArticle()`: si hay `openArticleId`, hace `_reload(readArticleId: openArticleId)` (queda `null` por default).
- [x] 1.5 Tests de `InboxCubit`/`bloc_test` para `selectArticle` (primera selección, cambio de selección, mismo artículo) y `closeOpenArticle` (con y sin selección previa).

## 2. UI del Inbox (modo expandido)

- [x] 2.1 En `InboxView` (modo `WindowSizeClass.expanded`), reemplazar la llamada a `cubit.markAsRead(article.id)` por `cubit.selectArticle(article.id)` en el `onTap`.
- [x] 2.2 Agregar parámetro `isOpen`/`isSelected` a `ArticleInboxTile` y pintar el fondo de la fila con `theme.colorScheme.secondaryContainer` cuando corresponda; pasar `article.id == loaded.openArticleId` desde `InboxView`.
- [x] 2.3 Verificar que `buildWhen`/`listenWhen` de `InboxView` siguen disparando `_animateDismiss` correctamente cuando `readArticleId` viene acompañado de un `openArticleId` nuevo (no solo `null`).
- [x] 2.4 Widget test: tocar un artículo en modo expandido lo resalta y no lo remueve de la lista.
- [x] 2.5 Widget test: seleccionar un segundo artículo remueve (anima salida) el primero y resalta el segundo.

## 3. Cierre desde el panel derecho (botón de volver)

- [x] 3.1 En `router.dart`, crear un placeholder específico para la raíz de la branch de Inbox en modo expandido (envolviendo `EmptyDetailPlaceholder`) que, en su `initState`, llame a `context.read<InboxCubit>().closeOpenArticle()`.
- [x] 3.2 Confirmar que Favoritos/Archivo/Fuentes/Resúmenes siguen usando el `_articleListRoot` genérico sin este comportamiento (no tienen `openArticleId`).
- [x] 3.3 Cubierto a nivel de `InboxCubit.closeOpenArticle()` (tests de la sección 1: anima la salida y limpia `openArticleId`). No se agregó un test de integración a través de `router.dart` real: ejercitarlo exigiría registrar en `getIt` toda la cadena de dependencias de `ReaderScreen` (`MarkArticleAsRead`/`ToggleFavorite` y sus repos), algo que ningún test existente del repo hace hoy para `router.dart` -- la app no tiene tests de navegación end-to-end (ver convención de CLAUDE.md: pruebas manuales de navegación en simulador las hace el usuario). El único código nuevo en `router.dart` es una línea de wiring (`context.read<InboxCubit>().closeOpenArticle()` en `initState` de `_EmptyArticleDetail`), verificada por `flutter analyze` y por revisión manual del usuario en simulador.

## 4. Verificación cruzada

- [x] 4.1 Confirmar que cambiar de tab (Favoritos/Archivo/etc.) y volver al Inbox conserva el artículo resaltado y abierto (sin llamar a `closeOpenArticle` ni `selectArticle`). Por diseño: cambiar de tab no reconstruye la ruta raíz de la branch de Inbox (`StatefulShellRoute.indexedStack` preserva cada branch), así que `_EmptyArticleDetail.initState` no se vuelve a ejecutar, y `InboxCubit` es un singleton cuyo `openArticleId` no se toca al navegar entre tabs.
- [x] 4.2 Confirmar que el modo compacto (`WindowSizeClass.compact`) no cambia: sigue usando `context.push` + `loadArticlesAfterReading` sin pasar por `selectArticle`/`openArticleId` (ver rama `if (context.windowSizeClass == WindowSizeClass.expanded)` en `inbox_screen.dart`, sin tocar el branch `else`).
- [x] 4.3 Revisar visualmente el color de resaltado (`secondaryContainer`) en light y dark theme. Es el mismo token ya calibrado para el indicador de selección del NavigationDrawer/NavigationRail en ambos temas (`app_theme.dart`); pendiente confirmación visual del usuario en simulador.
- [x] 4.4 `flutter analyze` sin warnings nuevos.
- [x] 4.5 `flutter test` (unit + widget) en verde.
