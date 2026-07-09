## 1. Fix

- [x] 1.1 En `HiveArticleDatasource.getArchive()`, cambiar el sort de `readAt ?? publishedAt` a `publishedAt` para que el orden sea descendente por fecha de publicación, igual que `getInboxArticles()`

## 2. Tests

- [x] 2.1 Actualizar o agregar test de `HiveArticleDatasource.getArchive()` que verifique el orden descendente por `publishedAt`
- [x] 2.2 Correr `flutter test` y `flutter analyze` sin errores
