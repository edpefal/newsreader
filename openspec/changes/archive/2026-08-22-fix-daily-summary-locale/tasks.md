## 1. Cliente Flutter — threadear el locale activo hasta el request

- [x] 1.1 `core/ai/summary_generator.dart`: agregar `required String language` a la firma de `SummaryGenerator.summarize`
- [x] 1.2 `core/ai/gemini_summary_generator.dart`: incluir `language` en el body del POST a `summarize-articles`
- [x] 1.3 `features/summaries/domain/usecases/generate_daily_summary.dart`: `execute` recibe `String language` y lo pasa a `_summaryGenerator.summarize`
- [x] 1.4 `features/summaries/presentation/cubit/summaries_cubit.dart`: `generateTodaySummary`/`_generate` reciben y threadean `language` hasta `GenerateDailySummary.execute`
- [x] 1.5 `features/summaries/presentation/screens/summaries_screen.dart`: leer `Localizations.localeOf(context).languageCode` en el `onPressed` del botón y pasarlo a `cubit.generateTodaySummary(language)`

## 2. Backend — prompt parametrizado por idioma

- [x] 2.1 Extraer la lógica de idioma soportado/default a un archivo propio (`supabase/functions/summarize-articles/language.ts`), mismo patrón que `entitlement.ts`: una función que valida `language` contra `["en", "es", "fr"]` y devuelve `"es"` como default si no matchea o falta
- [x] 2.2 `buildPrompt` pasa a tomar `language` como parámetro y selecciona la versión correspondiente del texto de instrucciones (voz editorial, qué sí/qué no, ejemplo "MAL/BIEN") en inglés, español o francés — misma estructura de reglas de formato de salida en los 3 idiomas
- [x] 2.3 `index.ts`: leer `language` del body de la request, resolverlo con la función de 2.1, y pasarlo a `buildPrompt`

## 3. Tests

- [x] 3.1 `test/unit/core/ai/gemini_summary_generator_test.dart`: actualizar para pasar `language` y verificar que se incluye en el body del POST
- [x] 3.2 `test/unit/features/summaries/domain/usecases/generate_daily_summary_test.dart` (crear si no existe, o actualizar el test existente del usecase): verificar que `execute` threadea el `language` recibido hacia `SummaryGenerator.summarize`
- [x] 3.3 `test/unit/features/summaries/presentation/cubit/summaries_cubit_test.dart`: actualizar para pasar `language` a `generateTodaySummary` y verificar que llega hasta el usecase
- [x] 3.4 `test/widget/features/summaries/summaries_screen_test.dart`: verificar que el botón dispara `generateTodaySummary` con el `languageCode` del locale activo del widget test
- [x] 3.5 `supabase/functions/summarize-articles/language_test.ts`: unit test Deno de la función de validación/default (idioma soportado, no soportado, ausente)

## 4. Verificación final

- [x] 4.1 Correr `flutter analyze` y resolver cualquier warning
- [x] 4.2 Correr `flutter test` (unit + widget) y confirmar que todo pasa
- [x] 4.3 Probar manualmente: generar el resumen diario con la app en inglés y en francés (cambiando el locale del simulador/dispositivo), confirmar que el texto sale en ese idioma (inglés: confirmado en dispositivo real; francés: confirmado en dispositivo real); `language` inválido/ausente cae a inglés — verificado vía `language_test.ts` contra el código real deployado (sin sesión real disponible para probarlo end-to-end por HTTP)
