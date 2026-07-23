## 1. Reestructurar el router

- [x] 1.1 En `lib/presentation/app/router.dart`, mover el `GoRoute` de `/sources/:id` (`SourceDetailScreen`) de estar anidado dentro del branch `/sources` a ser un `GoRoute` de nivel superior (hermano de `StatefulShellRoute`), con el mismo `path` y misma lógica de `extra`.
- [x] 1.2 Mover `/sources/add` (`AddSourceScreen`) de la misma forma, a nivel superior.
- [x] 1.3 Mover `/sources/import-opml` (`ImportOpmlScreen`) de la misma forma, a nivel superior.
- [x] 1.4 Mover `/summaries/:date` (`SummaryDetailScreen`) de la misma forma, a nivel superior.
- [x] 1.5 Confirmar que el branch `/sources` en `StatefulShellRoute` queda solo con la ruta raíz `/sources` (`SourcesScreen`), y el branch `/summaries` queda solo con la ruta raíz `/summaries` (`SummariesScreen`).

## 2. Verificación

- [x] 2.1 Correr `flutter analyze` y resolver cualquier warning.
- [x] 2.2 Correr `flutter test` y confirmar que todo pasa (sin cambios esperados en tests existentes, ya que ningún widget/cubit cambia).
- [x] 2.3 Probar manualmente en el emulador: navegar a Fuentes → detalle de una fuente → confirmar que se ve una sola barra superior (back + nombre de la fuente, sin el hamburger/"Fuentes" arriba). Verificado con "Noted".
- [x] 2.4 Probar manualmente: Fuentes → "Agregar fuente" → confirmar una sola barra. Agregar una fuente y confirmar que la lista se recarga al volver. Verificado manualmente por el usuario.
- [x] 2.5 Probar manualmente: Fuentes → "Importar OPML" → confirmar una sola barra. Verificado manualmente por el usuario.
- [x] 2.6 Probar manualmente: Resúmenes → detalle de un resumen → confirmar una sola barra (back + fecha del resumen). Verificado manualmente por el usuario.
- [x] 2.7 Confirmar que cambiar entre tabs (Inbox, Favoritos, Leídos, Fuentes, Resúmenes) sigue preservando el estado de cada uno (scroll, etc.) como antes. Verificado manualmente por el usuario.
