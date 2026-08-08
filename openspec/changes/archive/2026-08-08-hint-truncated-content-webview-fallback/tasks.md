## 1. `ReaderScreen`: aviso tocable de contenido truncado

- [x] 1.1 Importar `FeedContentChecker` en `reader_screen.dart` y usarlo en `_buildContent` en vez del chequeo actual `contentHtml != null`, para decidir si mostrar el aviso.
- [x] 1.2 Reestructurar `_buildContent` para devolver una `Column` con el contenido disponible (HTML o excerpt, si hay) seguido del aviso cuando `FeedContentChecker.isTruncated(article.contentHtml)` es `true`. Quitar el texto genérico "Contenido no disponible en el feed." (queda cubierto por el aviso nuevo).
- [x] 1.3 El aviso es un widget tocable (`InkWell`/`GestureDetector`) con ícono + texto, que al tocarse ejecuta la misma navegación que el botón "Ver en navegador" del AppBar (`context.push('/article/${article.id}/web', extra: article)`).

## 2. Tests

- [x] 2.1 Actualizar `test/widget/features/reader/reader_screen_test.dart`: el test existente "muestra fallback cuando no hay contentHtml ni excerpt" debe reflejar el nuevo texto/aviso en vez del mensaje eliminado. (También se ajustó el fixture compartido `tArticle` a 500+ caracteres y los finders de "Ver en navegador" del AppBar a `widgetWithIcon(IconButton, ...)`, para desambiguar del ícono nuevo del aviso.)
- [x] 2.2 Agregar test: artículo con `excerpt` pero sin `contentHtml` muestra el excerpt Y el aviso (hoy el test existente "muestra excerpt cuando contentHtml es nulo" solo verifica el excerpt).
- [x] 2.3 Agregar test: artículo con `contentHtml` corto (menor a 500 caracteres) muestra ese contenido y el aviso (caso no cubierto hoy, ya que `_buildContent` no chequeaba longitud).
- [x] 2.4 Agregar test: artículo con `contentHtml` de 500+ caracteres no muestra ningún aviso.
- [x] 2.5 Agregar test: tocar el aviso navega a `/article/:id/web`, igual que el botón del AppBar.

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` sin warnings nuevos.
- [x] 3.2 Correr `flutter test test/widget/features/reader/` y confirmar que todo pasa.
- [x] 3.3 Probar manualmente en la app: abrir un artículo de `tldr.tech` (sin contenido) y confirmar que aparece el aviso y que tocarlo abre el WebView.
