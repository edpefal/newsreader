## Why

Los usuarios que suscriben muchas fuentes reciben más artículos de los que pueden leer en el día. Un resumen diario generado por IA les permite tener una vista rápida de qué llegó ese día, organizado por fuente.

**Nota de pivote (post-implementación inicial):** la v1 de este proposal usaba un LLM on-device (`flutter_gemma`) para mantener todo el procesamiento local y privado. En pruebas reales en dispositivo, los modelos livianos que no requieren autenticación (SmolLM 135M, Qwen 2.5 0.5B) dieron resultados de calidad insuficiente (repetición, alucinaciones, no seguían la instrucción de responder en español) o requerían gating de HuggingFace (familia Gemma) que hubiera exigido pedirle a cada usuario final una cuenta y token de HuggingFace — inviable para una app de noticias consumer. Se migró a una API de IA en la nube (Gemini, vía un backend propio en Supabase Edge Functions) para lograr calidad aceptable. Ver `design.md` para el detalle de la decisión y alternativas descartadas.

## What Changes

- Se agrega una nueva pantalla "Resúmenes" accesible como quinta rama del drawer de navegación (`/summaries`), junto a Inbox/Favoritos/Leídos/Fuentes.
- El resumen se genera por fuente: se agrupan los artículos de hoy por `sourceName` y se pide un párrafo por cada una, con el nombre de la fuente antepuesto por código (nunca generado por el modelo).
- Se agrega una Supabase Edge Function (`summarize-articles`) que actúa de proxy a la API de Gemini — la app nunca llama a Gemini directamente ni contiene su API key; se autentica ante el backend propio con el anon key público de Supabase.
- El botón "Crear resumen" se deshabilita si no hay artículos de hoy en el inbox.
- Cada generación para el día de hoy sobrescribe el resumen existente de ese día (upsert por fecha); un día distinto crea un nuevo item en la lista.
- La lista de resúmenes muestra un item por día (más reciente primero) con fecha y cantidad de artículos resumidos; tocar un item abre una pantalla de detalle con el texto completo.
- Fuera de alcance: regeneración de resúmenes de días pasados, resumir artículos leídos/archivados/favoritos, protección anti-abuso del endpoint más allá del anon key de Supabase.

## Capabilities

### New Capabilities
- `daily-summaries`: generación, almacenamiento y visualización de resúmenes diarios de IA a partir de los artículos del inbox del día actual, agrupados por fuente, con upsert por fecha.

### Modified Capabilities
(ninguna — no cambia el comportamiento de capabilities existentes como `article-lifecycle` o `source-management`)

## Impact

- Nuevo feature `features/summaries/` (domain/usecases + presentation: cubit, screens, widgets).
- Nueva entidad `DailySummary` en `core/domain/entities/` y repositorio `SummaryRepository` en `core/domain/repositories/`.
- Nueva abstracción `SummaryGenerator` en `core/ai/` (análoga a `FeedParser`/`HttpClient`), implementada por `GeminiSummaryGenerator`, que llama al backend propio vía la abstracción `HttpClient` existente (se le agregó el método `post`).
- Nuevo `HiveModel` para `DailySummary` con su propio `typeId` (siguiente disponible tras 0=NewsSourceModel, 1=ArticleModel) y su datasource local; requiere regenerar TypeAdapters con `build_runner`.
- Nuevo directorio `supabase/functions/summarize-articles/` con el código de la Edge Function (Deno/TypeScript) desplegada en un proyecto propio de Supabase.
- Cambios en `lib/presentation/app/router.dart` (nueva rama del `StatefulShellRoute` + item del drawer) y en `core/di/injection.dart` (registro de las nuevas dependencias).
- Sin cambios de compatibilidad de plataforma (se evaluó y luego se revirtió el bump de `IPHONEOS_DEPLOYMENT_TARGET` a 16.0, ya no es necesario al no depender de `flutter_gemma`).
