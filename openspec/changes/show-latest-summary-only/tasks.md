## 1. Dominio y Cubit

- [x] 1.1 Crear el use case `GetLatestDailySummary` (`features/summaries/domain/usecases/`) que devuelve el `DailySummary` más reciente o `null`, y registrarlo en `core/di/injection.dart`; eliminar `GetDailySummaries` y su registro
- [x] 1.2 Cambiar `SummariesLoaded` a `DailySummary? summary` y `SummariesCubit` para usar `GetLatestDailySummary`
- [x] 1.3 Tests: reemplazar `get_daily_summaries_test.dart` por el del nuevo use case (incluye que con varios resúmenes devuelve el de fecha más reciente y que sin resúmenes devuelve `null`) y actualizar `summaries_cubit_test.dart`

## 2. Presentación: cuerpo del resumen y pantalla de la tab

- [x] 2.1 Extraer de `SummaryDetailScreen` el widget `SummaryDetailBody` (un archivo en `presentation/widgets/`), sin `Scaffold`/`AppBar`, con la fecha larga localizada como primer elemento del contenido, `onOpened` y el ancho máximo de 680pt
- [x] 2.2 Reducir `SummaryDetailScreen` a `Scaffold` + `AppBar` (título "Resumen del {fecha}") + `SummaryDetailBody`; verificar que la ruta del Inbox (`/summary/:id`) se ve y se comporta igual
- [x] 2.3 Reescribir `SummariesScreen`: `SummariesLoading` → indicador; `summary == null` → estado vacío; en otro caso `SummaryDetailBody` con `onOpened` que descarta la tarjeta de hoy (`DismissDailySummary`) y la acción de abrir un artículo hacia `/summaries/article/:articleId` (preferir `AppNavigator`/`RouteExtraResolver` antes que ampliar el uso directo de `go_router`)
- [x] 2.4 Eliminar `SummaryListItem` y todo uso de la lista
- [x] 2.5 Tests de widget: actualizar `summaries_screen_test.dart` (estado vacío, un resumen, varios → solo el más reciente, sin lista) y `summary_detail_screen_test.dart` (cuerpo con fecha dentro del contenido, detalle del Inbox con su AppBar)

## 3. Rutas y layout adaptativo

- [x] 3.1 En `router.dart`, eliminar la ruta `/summaries/:date` y anidar el lector bajo `/summaries` como `article/:articleId` (`_articleRoute(paramName: 'articleId')`)
- [x] 3.2 Pasar a `AdaptiveListDetailScaffold` un `listWidth` mayor para Resúmenes y verificar que `_adaptiveBranchShell` lo recibe sin afectar las otras tabs
- [x] 3.3 Actualizar el placeholder del panel derecho de `/summaries` (copy de "elige un artículo")
- [x] 3.4 Confirmar qué muestra la app al abrir `/summaries/<fecha>` o `/summaries/<fecha>/article/<id>` (ruta no encontrada) y que no deja una pantalla en blanco ni rompe la navegación restaurada (el router no define `errorBuilder`: aparece la pantalla de error por defecto de `go_router`, sin crash ni pantalla en blanco; solo es alcanzable por estado de navegación restaurado de una versión anterior)
- [x] 3.5 Revisar `SummariesCubit.loadSummaries()` en `adaptive_shell.dart` y en `app.dart`/`main.dart`: sigue recargándose al entrar a la tab y no queda código que espere la lista
- [x] 3.6 Razonar y dejar anotado el comportamiento en ≥840dp: rail, resumen a la izquierda, lector a la derecha, selección del artículo preservada al cruzar el umbral (la prueba manual en iPad la corre el usuario)

## 4. Textos (i18n)

- [x] 4.1 Reescribir `summariesEmptySubtitle` en `app_en.arb`, `app_es.arb` (español neutro con tuteo) y `app_fr.arb`: aún no hay resúmenes y se creará uno más adelante
- [x] 4.2 Reescribir `summariesSelectSummaryTitle`/`summariesSelectSummarySubtitle` como "elige un artículo" en los 3 `.arb` (renombrar las claves si ya no describen un resumen)
- [x] 4.3 Eliminar las claves que quedan sin uso (por ejemplo las del item de lista) de los 3 `.arb`, correr `flutter gen-l10n` y `flutter test test/unit/l10n/`

## 5. Verificación y cierre

- [x] 5.1 `flutter analyze` sin warnings y `flutter test` en verde
- [x] 5.2 `dart format` solo sobre los archivos tocados; revisar `git diff --stat`
- [x] 5.3 `openspec validate show-latest-summary-only --strict`
- [ ] 5.4 Pruebas manuales del usuario en simulador/iPad: usuario nuevo (estado vacío), con varios resúmenes (solo el último), abrir un artículo desde el resumen en compact y en iPad, rotar con un artículo abierto, y que la tarjeta del Inbox desaparece al entrar a la tab
- [ ] 5.5 Abrir PR contra `main`, esperar `analyze-and-test` en verde y mergear; archivar el change (`openspec archive show-latest-summary-only --yes`, o fusión manual con `--skip-specs` si el CLI rechaza el RENAMED + MODIFIED) en el mismo PR final y borrar la rama
