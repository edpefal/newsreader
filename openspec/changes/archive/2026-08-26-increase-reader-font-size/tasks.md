## 1. Tipografía del lector

- [x] 1.1 En `lib/core/widgets/fwh_html_content_renderer.dart`, aumentar el `fontSize` del branch `readerMode: true` de 18 a 20, manteniendo `height: 1.7` y `letterSpacing: 0.2`.
- [x] 1.2 En `lib/features/reader/presentation/screens/reader_screen.dart`, pasar `readerMode: true` al construir `FwhHtmlContentRenderer` para el cuerpo del artículo.

## 2. Verificación

- [x] 2.1 Correr `flutter analyze` y confirmar que no hay warnings nuevos.
- [x] 2.2 Correr la app y abrir un artículo con contenido HTML normal: confirmar que el texto se ve notablemente más grande que antes y que el interlineado se ve cómodo.
- [x] 2.3 Abrir un artículo con imágenes embebidas y confirmar que el layout no se rompe con el nuevo tamaño de fuente.
- [x] 2.4 Abrir un artículo detectado como HTML crudo de email (renderizado en WebView) y confirmar que su apariencia no cambió.
- [x] 2.5 Confirmar visualmente que el tamaño de fuente en las listas de inbox/archivo/favoritos no cambió.
