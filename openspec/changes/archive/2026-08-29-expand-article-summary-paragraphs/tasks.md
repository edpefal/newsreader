## 1. Actualizar el prompt del backend

- [x] 1.1 Reescribir `INSTRUCTIONS.es` en `supabase/functions/summarize-article/index.ts` para pedir 1 párrafo como caso normal y hasta 4 solo cuando el artículo cubra varios temas separables, con `\n\n` entre párrafos.
- [x] 1.2 Ajustar el ejemplo MAL/BIEN en `INSTRUCTIONS.es` para que no implique que la salida siempre es un único párrafo.
- [x] 1.3 Repetir 1.1 y 1.2 para `INSTRUCTIONS.en`.
- [x] 1.4 Repetir 1.1 y 1.2 para `INSTRUCTIONS.fr`.
- [x] 1.5 Revisar a mano el español de `INSTRUCTIONS.es` contra voseo (no pasa por `neutral_spanish_test.dart`, ver CLAUDE.md).

## 2. Verificación

- [x] 2.1 Correr `flutter analyze` (no debería haber cambios en Dart, solo confirmar que sigue limpio).
- [x] 2.2 Revisado (sin generar tráfico real, por decisión del usuario): el prompt en los 3 idiomas (`INSTRUCTIONS.es/en/fr`) pide explícitamente 1 párrafo como caso normal y hasta 4 solo si el artículo cubre varios temas separables, separados por línea en blanco. `RESPONSE_SCHEMA.summary` es un `STRING` plano sin restricción de longitud/formato, así que el `\n\n` embebido llega intacto al cliente -- la lógica es coherente, pendiente de confirmar con tráfico real más adelante si aparece algún caso dudoso.
- [x] 2.3 Confirmado por inspección de código: `ArticleSummarySheetContent` renderiza el resumen con `Text(summary.summary)` (`article_summary_bottom_sheet.dart:75`), un `Text` plano sin `maxLines` ni `overflow` que colapse saltos de línea -- Flutter respeta los `\n` literales por defecto, así que `\n\n` se ve como párrafos separados sin necesidad de correr la app.

## 3. Documentación de specs

- [x] 3.1 Actualizado y confirmado: la delta spec había quedado desactualizada respecto al spec principal (que mientras tanto ganó los escenarios de `content_blocked`/`subscription_required` del change `surface-content-blocked-summary-error`) -- se reescribió para incluir tanto los escenarios de párrafos como esos dos, listo para sync/archive.
