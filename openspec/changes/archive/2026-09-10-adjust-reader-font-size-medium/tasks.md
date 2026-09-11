## 1. Ajuste de tamaño de fuente

- [x] 1.1 En `lib/core/widgets/fwh_html_content_renderer.dart`, cambiar `fontSize: 20` a `fontSize: 18` en el `textStyle` del branch `readerMode: true`.
- [x] 1.2 Revisar visualmente si `height: 1.7` sigue siendo cómodo con 18px; ajustar solo si el interlineado se ve desproporcionado.
- [x] 1.3 Correr `flutter analyze` y `flutter test`.

## 2. Verificación

- [x] 2.1 Confirmar que las listas de artículos (inbox, archivo, favoritos) no cambiaron de tamaño de fuente.
- [x] 2.2 Avisar al usuario para que verifique manualmente en simulador/dispositivo la legibilidad del nuevo tamaño (18px) en un artículo largo.
