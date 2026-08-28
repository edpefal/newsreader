## 1. Backend: `summarize-article`

- [x] 1.1 Crear `supabase/functions/summarize-article/index.ts`, reusando `entitlement.ts`, `language.ts` y el patrón de auth de `summarize-articles` (validar sesión, chequear entitlement, chequear/registrar cuota vía `check_and_record_ai_usage`)
- [x] 1.2 Definir prompt de un solo artículo (título + contenido) que le pida a Gemini resumen + lista de menciones (libro/podcast/música), y configurar `responseSchema` (`generationConfig.responseMimeType: "application/json"` + `responseSchema`) para forzar `{ summary, mentions: [{ type, name }] }`
- [x] 1.3 Validar el JSON recibido de Gemini (shape, tipos permitidos de `mentions`); responder `generationFailed` si no matchea
- [x] 1.4 Reusar el conteo de palabras (extender o adaptar `word_count.ts`) para un solo artículo
- [x] 1.5 Tests: entitlement, idioma, parseo de respuesta válida/ inválida, rechazo por cuota agotada (seguir el estilo de `entitlement_test.ts`/`language_test.ts`/`word_count_test.ts`)

## 2. Backend: `enrich-mentions`

- [x] 2.1 Crear `supabase/functions/enrich-mentions/index.ts`: valida sesión (mismo patrón de auth), recibe `{ mentions: [{ type, name }] }`
- [x] 2.2 Implementar resolución por tipo: `book` → Google Books API (búsqueda por título), `podcast`/`music` → iTunes Search API (parámetro `entity` correspondiente)
- [x] 2.3 Devolver `{ mentions: [{ type, name, imageUrl?, link? }] }`; mención sin match del proveedor se devuelve sin `imageUrl`/`link` (no se omite)
- [x] 2.4 Manejar falla de un proveedor puntual sin abortar el resto de las menciones de la misma request
- [x] 2.5 Tests unitarios de la función de resolución por tipo (mockeando las respuestas de Google Books/iTunes)

## 3. App: dominio y abstracción `MentionEnricher`

- [x] 3.1 Crear `core/ai/mention_enricher.dart` (interfaz genérica `MentionEnricher`, tipos `MentionType`, `RawMention`, `EnrichedMention`)
- [x] 3.2 Crear `core/ai/remote_mention_enricher.dart` (implementación que llama a `enrich-mentions` vía `HttpClient`)
- [x] 3.3 Extender `core/ai/summary_generator.dart` (o agregar interfaz hermana) con un método para resumir un artículo único devolviendo `{ summary, mentions crudas }`
- [x] 3.4 Implementar `core/ai/gemini_article_summary_generator.dart` (o método nuevo en `GeminiSummaryGenerator`) que llama a `summarize-article`
- [x] 3.5 Crear entidad `core/domain/entities/article_summary.dart` (`articleId`, `summary`, `mentions: List<EnrichedMention>`, `createdAt`)
- [x] 3.6 Crear `core/domain/repositories/article_summary_repository.dart` (interfaz: `getByArticleId`, `save`)

## 4. App: persistencia Hive

- [x] 4.1 Crear `core/data/models/article_summary_model.dart` con `@HiveType(typeId: 3)` y generar el TypeAdapter (`build_runner`)
- [x] 4.2 Crear `core/data/datasources/local/article_summary_local_datasource.dart` (interfaz + implementación Hive, box nueva)
- [x] 4.3 Crear `core/data/repositories/article_summary_repository_impl.dart`
- [x] 4.4 Abrir la nueva box en `main.dart` junto a las existentes; registrar en `core/di/injection.dart`

## 5. App: feature `features/article_summary`

- [x] 5.1 Crear `features/article_summary/domain/usecases/generate_article_summary.dart`: orquesta lookup local → generación (si no existe) → enriquecimiento → persistencia, según el flujo de `design.md`
- [x] 5.2 Crear `ArticleSummaryCubit` con estados (cargando/listo/error) — el chequeo de suscripción se resolvió a nivel UI (ver 5.3), no dentro del cubit, para no acoplarlo al ciclo de vida del paywall
- [x] 5.3 Integrar el chequeo de entitlement y el paywall de Superwall en el botón del `ReaderScreen` (mismo patrón que `SummariesView._onGeneratePressed`), con el mismo comportamiento post-cierre-de-paywall que `daily-summaries` (revalidar suscripción antes de abrir el bottom sheet)
- [x] 5.4 Agregar el botón en el AppBar de `ReaderScreen` que abre el bottom sheet
- [x] 5.5 Crear el widget del bottom sheet (texto del resumen + lista de mention cards)
- [x] 5.6 Crear el widget de mention card: variante enriquecida (imagen + tap abre navegador del sistema vía `url_launcher`) y variante texto plano (sin imagen, sin tap)

## 6. i18n

- [x] 6.1 Agregar claves nuevas a `lib/l10n/app_en.arb` (botón, título del bottom sheet, título de menciones — los estados de error reusan `AppErrorCode`s ya existentes, sin claves nuevas)
- [x] 6.2 Traducir a `lib/l10n/app_es.arb` (español neutro, sin voseo) y `lib/l10n/app_fr.arb`
- [x] 6.3 Correr `flutter gen-l10n`

## 7. Tests de la app

- [x] 7.1 Unit tests de `GenerateArticleSummary` (lookup local hit/miss, orquestación generación+enriquecimiento, fallo de enriquecimiento no bloquea persistencia del resumen)
- [x] 7.2 Bloc tests de `ArticleSummaryCubit` (con `bloc_test`, mocks con `mocktail`) cubriendo los escenarios de `article-summaries` y `article-mentions`
- [x] 7.3 Widget tests del bottom sheet y de las mention cards (enriquecida vs texto plano)

## 8. Verificación final

- [x] 8.1 `flutter analyze` sin warnings
- [x] 8.2 `flutter test` completo en verde (496/497; el único fallo, `localized_date_formatter_test.dart` "muestra hora HH:mm para hoy", es preexistente en `main` y depende de la hora local del sistema — no relacionado a este change)
- [x] 8.3 Deploy de las dos Edge Functions nuevas a dev (`xgwnxhpdcrghrtdbrmpn`) y prod (`avyaxzhdilhufyimrzzb`); `GEMINI_API_KEY` ya existía como secret en ambos proyectos
