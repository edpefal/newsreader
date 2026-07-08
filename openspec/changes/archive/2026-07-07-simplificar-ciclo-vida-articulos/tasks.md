## 1. Migración de datos existentes

- [x] 1.1 Crear `lib/features/maintenance/domain/usecases/migrate_archived_articles.dart` con use case que elimina todos los artículos con `isArchived=true` de Hive
- [x] 1.2 Registrar `MigrateArchivedArticles` en `lib/core/di/injection.dart`
- [x] 1.3 Reemplazar la llamada `getIt<RunMaintenance>().execute()` en `main.dart` por `getIt<MigrateArchivedArticles>().execute()`

## 2. Eliminar RunMaintenance

- [x] 2.1 Eliminar `lib/features/maintenance/domain/usecases/run_maintenance.dart`
- [x] 2.2 Eliminar el registro de `RunMaintenance` en `lib/core/di/injection.dart`
- [x] 2.3 Eliminar métodos `getReadArticlesOlderThan` y `getUnreadNonArchivedArticlesOlderThan` de la interfaz `ArticleRepository` (`lib/core/domain/repositories/article_repository.dart`)
- [x] 2.4 Eliminar la implementación de esos métodos en `ArticleRepositoryImpl` (`lib/core/data/repositories/article_repository_impl.dart`)
- [x] 2.5 Eliminar los métodos `getReadArticlesOlderThan` y `getUnreadNonArchivedArticlesOlderThan` de `ArticleLocalDataSource` y `HiveArticleDatasource`

## 3. Corregir queries

- [x] 3.1 En `HiveArticleDatasource.getInboxArticles()`: cambiar filtro de `!a.isRead && !a.isArchived` a `!a.isRead`
- [x] 3.2 En `HiveArticleDatasource.getArchive()`: cambiar filtro de `a.isArchived && !a.isRead` a `a.isRead`, y cambiar sort de `publishedAt` a `readAt ?? publishedAt` descendente

## 4. Tests

- [x] 4.1 Eliminar `test/unit/features/maintenance/` (si existe)
- [x] 4.2 Actualizar tests de `HiveArticleDatasource` para reflejar los nuevos filtros de inbox y archive
- [x] 4.3 Escribir unit test para `MigrateArchivedArticles`: verifica que elimina artículos con `isArchived=true` y no toca los demás
- [x] 4.4 Correr `flutter test` y resolver cualquier fallo

## 5. Verificación final

- [x] 5.1 Correr `flutter analyze` y resolver warnings
- [x] 5.2 Probar en simulador: abrir artículo desde inbox → verificar que aparece en "Leídos"
- [x] 5.3 Probar en simulador: artículos viejos no leídos permanecen en inbox
