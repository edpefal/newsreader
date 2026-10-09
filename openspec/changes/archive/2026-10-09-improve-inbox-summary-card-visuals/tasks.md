## 1. Estado del Inbox

- [x] 1.1 Agregar `summarySourceIcons` (`Map<String, String?>`, `sourceId` → `iconUrl`) a `InboxLoaded` y a sus `props`
- [x] 1.2 Derivarlo en `InboxCubit._reload` desde la lista de fuentes que ya lee, limitado a los `sourceId` de `pendingSummary.sourceBlocks`
- [x] 1.3 Propagarlo en cada `emit(InboxLoaded(...))` existente del cubit
- [x] 1.4 En `_onPendingSummaryChanged`, conservar el mapa si cubre todos los `sourceId` del resumen y, si falta alguno, releer las fuentes antes de emitir
- [x] 1.5 Tests del cubit: mapa con íconos, fuente sin ícono, fuente eliminada, resumen sin `sourceBlocks`, y resumen nuevo por stream con una fuente que no estaba

## 2. Tarjeta

- [x] 2.1 `InboxSummaryCard` recibe `summarySourceIcons` por constructor
- [x] 2.2 Avatar circular de 34px con `CachedNetworkImageWidget`, anillo de 2px del color del relleno y fallback a la inicial sobre círculo translúcido
- [x] 2.3 Ícono `Icons.auto_awesome_outlined` de 16 a la izquierda del título, fuera del árbol semántico
- [x] 2.4 Radio 14 en la tarjeta, en el borde del estado seleccionado y en `_SwipeDismissBackground`
- [x] 2.5 `InboxScreen` pasa el mapa desde `InboxLoaded` a la tarjeta
- [x] 2.6 Verificar que el CTA, el swipe, la etiqueta semántica y el estado "Abierto" no cambian

## 3. Tests de widget

- [x] 3.1 Actualizar `inbox_summary_card_test.dart`: avatar con ícono, fuente sin ícono, ícono de destello presente y no anunciado, resumen sin agrupación
- [x] 3.2 Actualizar `inbox_screen_summary_card_test.dart` con el nuevo parámetro/estado

## 4. Verificación

- [x] 4.1 `flutter analyze` sin warnings
- [x] 4.2 `flutter test` completo en verde
- [x] 4.3 Razonar el layout en ≥840dp (columna central del master-detail, selección y "Abierto")
- [x] 4.4 Pruebas manuales por el usuario (claro, oscuro, ícono óxido sobre óxido, fuente sin ícono, swipe de descarte) — se verifican en TestFlight tras el merge; si aparece un problema, va en un change aparte
