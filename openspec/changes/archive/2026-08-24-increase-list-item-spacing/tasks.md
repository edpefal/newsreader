## 1. Espaciado en tiles de artículo

- [x] 1.1 En `ArticleInboxTile` (`lib/features/inbox/presentation/widgets/article_inbox_tile.dart`), envolver el `ListTile` en un `Padding` vertical (constante `_verticalSpacing = 8.0`) sin alterar el contenido interno del tile.
- [x] 1.2 Verificar visualmente en inbox que el espacio entre dos artículos consecutivos del mismo día es perceptible y que el título largo sigue truncándose a 2 líneas.
- [x] 1.3 Verificar visualmente en archivo, favoritos y detalle de fuente que el mismo espaciado se aplica (reutilizan `ArticleInboxTile`), sin tocar esas pantallas.

## 2. Espaciado en tile de fuente

- [x] 2.1 En `_SourceTile` (`lib/features/sources/presentation/screens/sources_screen.dart`), envolver el `ListTile` en un `Padding` vertical con el mismo valor (`8.0`) usado en `ArticleInboxTile`.
- [x] 2.2 Verificar visualmente en la pantalla de fuentes que el espacio entre dos fuentes consecutivas es consistente con el de las listas de artículos.

## 3. Verificación final

- [x] 3.1 Correr `flutter analyze` y confirmar que no hay warnings nuevos.
- [x] 3.2 Correr `flutter test` y confirmar que los tests existentes (incluyendo widget tests de inbox/archive/favorites/sources) siguen pasando.
