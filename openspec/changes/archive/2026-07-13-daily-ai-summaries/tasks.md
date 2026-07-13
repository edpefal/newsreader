## 1. Dependencias y compatibilidad

- [x] 1.1 Agregar `flutter_gemma` a `pubspec.yaml` y correr `flutter pub get`
- [x] 1.2 Subir `IPHONEOS_DEPLOYMENT_TARGET` de 13.0 a 16.0 en `ios/Runner.xcodeproj/project.pbxproj` (todas las configuraciones) y en `ios/Podfile` si aplica
- [x] 1.3 Verificar/ajustar configuración de Android (`arm64-v8a`) en `android/app/build.gradle.kts` si es necesario para `flutter_gemma`

## 2. Dominio compartido (core)

- [x] 2.1 Crear entidad `DailySummary` en `lib/core/domain/entities/daily_summary.dart` (id = `yyyy-MM-dd`, date, content, articleCount, createdAt), extendiendo `Equatable`
- [x] 2.2 Crear interfaz `SummaryRepository` en `lib/core/domain/repositories/summary_repository.dart` (`getAll()`, `save(DailySummary)`, `getByDate(DateTime)`)
- [x] 2.3 Crear interfaz `SummaryGenerator` en `lib/core/ai/summary_generator.dart` (método async que recibe lista de `(title, excerpt)` y devuelve el texto del resumen)

## 3. Infraestructura de datos (Hive)

- [x] 3.1 Crear `DailySummaryModel` en `lib/core/data/models/daily_summary_model.dart` con `@HiveType(typeId: 2)` y anotaciones de campos
- [x] 3.2 Correr `dart run build_runner build --delete-conflicting-outputs` para generar el `TypeAdapter`
- [x] 3.3 Registrar el nuevo `TypeAdapter` y abrir la box correspondiente en `main.dart`, junto a las boxes existentes
- [x] 3.4 Crear interfaz `SummaryLocalDataSource` en `lib/core/data/datasources/local/summary_local_datasource.dart`
- [x] 3.5 Implementar `HiveSummaryDatasource` en `lib/core/data/datasources/local/hive_summary_datasource.dart` (upsert por fecha usando la key `yyyy-MM-dd`)
- [x] 3.6 Implementar `SummaryRepositoryImpl` en `lib/core/data/repositories/summary_repository_impl.dart`

## 4. Integración con flutter_gemma

- [x] 4.1 Implementar `FlutterGemmaSummaryGenerator` en `lib/core/ai/flutter_gemma_summary_generator.dart`: verificar si el modelo está descargado, descargarlo si no, cargarlo, y ejecutar inferencia con el prompt de título+excerpt
- [x] 4.2 Definir y aplicar el tope de artículos/caracteres incluidos en el prompt para no exceder el contexto mínimo (~1024 tokens) del modelo elegido
- [x] 4.3 Mapear errores de descarga/inferencia de `flutter_gemma` a un tipo de error propio de la app (sin exponer excepciones de la librería fuera de `core/ai/`)

## 5. Feature `summaries` — dominio

- [x] 5.1 Crear usecase `GetDailySummaries` en `lib/features/summaries/domain/usecases/get_daily_summaries.dart` (lista ordenada por fecha descendente)
- [x] 5.2 Crear usecase `GenerateDailySummary` en `lib/features/summaries/domain/usecases/generate_daily_summary.dart`: obtiene artículos del inbox de hoy (no leídos, no archivados, `publishedAt` = hoy), invoca `SummaryGenerator`, guarda/sobrescribe el `DailySummary` de hoy vía `SummaryRepository`

## 6. Feature `summaries` — presentación

- [x] 6.1 Crear `SummariesCubit` y sus estados (`SummariesLoading`, `SummariesLoaded`, `SummaryGenerating`, `SummaryGenerationError`) en `lib/features/summaries/presentation/cubit/`, extendiendo `Equatable`
- [x] 6.2 Implementar en el cubit la lógica de habilitar/deshabilitar el botón según si hay artículos del inbox publicados hoy
- [x] 6.3 Crear `SummariesScreen` en `lib/features/summaries/presentation/screens/summaries_screen.dart`: lista de resúmenes + botón crear/regenerar + estados de carga/error
- [x] 6.4 Crear `SummaryDetailScreen` en `lib/features/summaries/presentation/screens/summary_detail_screen.dart`: texto completo, fecha y cantidad de artículos
- [x] 6.5 Crear widget de item de lista (`summary_list_item.dart`) propio del feature, siguiendo el patrón de los demás features

## 7. Navegación y DI

- [x] 7.1 Agregar rama `/summaries` al `StatefulShellRoute.indexedStack` en `lib/presentation/app/router.dart`, con ruta hija `/summaries/:date` para el detalle
- [x] 7.2 Agregar item "Resúmenes" al `NavigationDrawer` en `_ScaffoldWithNavBar` (icono + label + índice en `_titles`)
- [x] 7.3 Registrar en `lib/core/di/injection.dart`: `SummaryGenerator`, `SummaryLocalDataSource`, `SummaryRepository`, `GetDailySummaries`, `GenerateDailySummary`, y el `TypeAdapter`/box de `DailySummaryModel`

## 8. Tests

- [x] 8.1 Unit tests de `GenerateDailySummary` (con inbox vacío hoy, con artículos, sobrescritura del resumen existente) usando `mocktail`
- [x] 8.2 Unit tests de `GetDailySummaries` (orden descendente)
- [x] 8.3 Bloc tests de `SummariesCubit` con `bloc_test` (estados de carga, generación, error, botón deshabilitado sin artículos de hoy)
- [x] 8.4 Widget tests de `SummariesScreen` (lista vacía, lista con items, botón deshabilitado) envolviendo en `MultiBlocProvider` con mocks
- [x] 8.5 Widget tests de `SummaryDetailScreen`
- [x] 8.6 Correr `flutter analyze` y `flutter test` completos, sin warnings pendientes

## 9. Pivote a IA en la nube (Gemini + Supabase)

- [x] 9.1 Crear proyecto Supabase y Edge Function `summarize-articles` (`supabase/functions/summarize-articles/index.ts`) que recibe artículos, arma el prompt y llama a la API de Gemini
- [x] 9.2 Configurar secret `GEMINI_API_KEY` en Supabase y desplegar la función (`supabase functions deploy summarize-articles`)
- [x] 9.3 Verificar el endpoint desplegado con una request real antes de tocar la app
- [x] 9.4 Agregar método `post` a la interfaz `HttpClient` (`core/network/`) y su implementación en `HttpPackageClient`
- [x] 9.5 Crear `GeminiSummaryGenerator` en `lib/core/ai/gemini_summary_generator.dart` implementando `SummaryGenerator` vía `HttpClient.post`, autenticado con el anon key de Supabase
- [x] 9.6 Eliminar `flutter_gemma_summary_generator.dart`, quitar `flutter_gemma`/`flutter_gemma_mediapipe` de `pubspec.yaml`, revertir `IPHONEOS_DEPLOYMENT_TARGET` a 13.0 y `use_frameworks!` en `ios/Podfile`, correr `pod install`
- [x] 9.7 Actualizar `GenerateDailySummary` para agrupar artículos por `sourceName` e invocar `SummaryGenerator` una vez por fuente, anteponiendo el nombre por código
- [x] 9.8 Registrar `GeminiSummaryGenerator` en `injection.dart` en lugar de `FlutterGemmaSummaryGenerator`
- [x] 9.9 Actualizar tests de `GenerateDailySummary` para el agrupamiento por fuente; agregar tests unitarios de `GeminiSummaryGenerator` con `HttpClient` mockeado
- [x] 9.10 Correr `flutter analyze` y `flutter test` completos tras el pivote
