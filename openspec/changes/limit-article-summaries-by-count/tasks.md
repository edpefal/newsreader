## 1. Migración de Supabase

- [x] 1.1 Crear migración que agrega `summaries_used integer not null default 0` a `ai_usage_daily` y elimina `words_used`
- [x] 1.2 Reemplazar `check_and_record_ai_usage(p_words, p_daily_limit)` por `check_and_record_ai_usage(p_daily_limit integer)`: mismo lock de fila (`for update`) y reset por cambio de `day`, incrementando `summaries_used` en 1 en vez de sumar palabras
- [x] 1.3 Confirmar con el usuario a qué proyecto(s) de Supabase desplegar (`reevo` prod y/o `reevo-dev`) antes de aplicar la migración

## 2. Edge function `summarize-article`

- [x] 2.1 Cambiar la constante de límite a `AI_DAILY_SUMMARY_LIMIT = 25` (reemplaza `AI_DAILY_WORD_LIMIT`)
- [x] 2.2 Agregar el chequeo de techo de longitud (8,000 palabras, usando `countSingleArticleWords` ya existente) antes de llamar a `check_and_record_ai_usage`; si se supera, responder con el código de error nuevo `article_too_long` sin invocar a Gemini ni tocar `ai_usage_daily`
- [x] 2.3 Actualizar la llamada a `check_and_record_ai_usage` con la nueva firma; si `allowed=false`, responder con el código de error existente (renombrado si aplica) de límite diario alcanzado
- [ ] 2.4 Desplegar la edge function actualizada al/los proyecto(s) confirmados en 1.3 (`reevo` y `reevo-dev`) — pendiente, se hace antes de mergear el PR

## 3. Sincronización cliente de `ai_usage_daily`

- [x] 3.1 Agregar `ai_usage_daily` al patrón de sync de `CloudSyncClient.fetchChangedSince`, siguiendo el mismo enfoque que `sources`/`articles`/`daily_summaries`
- [x] 3.2 Persistir localmente (Hive, vía el datasource correspondiente en `core/data/datasources/local/`) el `summaries_used` y `day` sincronizados
- [x] 3.3 Exponer, desde el repositorio/datasource correspondiente, el consumo del día en curso y el restante (`25 - summaries_used`, o `25` si el `day` sincronizado no es hoy)

## 4. Cliente: errores y códigos

- [x] 4.1 Agregar `AppErrorCode.articleTooLongToSummarize` (o nombre equivalente) en `lib/core/errors/app_error_code.dart`
- [x] 4.2 Mapear el nuevo código de error del backend (`article_too_long`) en `lib/core/ai/gemini_article_summary_generator.dart`, junto al mapeo existente de límite diario
- [x] 4.3 Agregar las 3 traducciones (`app_en.arb`, `app_es.arb` con tuteo neutro sin voseo, `app_fr.arb`) para el mensaje de artículo demasiado largo, y actualizar el texto de límite diario alcanzado a la nueva unidad ("25 resúmenes" en vez de referencia a palabras) si el copy actual lo menciona
- [x] 4.4 Correr `flutter gen-l10n` tras tocar los `.arb`

## 5. Cliente: estado y UI del bottom sheet

- [x] 5.1 Agregar el estado nuevo al sealed `ArticleSummaryState` (ej. `ArticleSummaryLimitReached`) para el caso de límite diario alcanzado, separado de `ArticleSummaryError`
- [x] 5.2 Actualizar `ArticleSummaryCubit` para: (a) emitir el estado nuevo cuando el backend rechaza por límite diario, (b) seguir emitiendo `ArticleSummaryError` para el caso de artículo demasiado largo y demás errores existentes, (c) calcular y exponer `remainingToday` a partir de lo sincronizado en 3.3
- [x] 5.3 En `article_summary_bottom_sheet.dart`: agregar el case nuevo del `switch` para el estado de límite alcanzado, con superficie/tono neutro (paper/ink en light, dark surface/on-surface en dark) y copy "Ya usaste tus 25 resúmenes de hoy. Vuelven mañana a las 00:00." (sin ícono de alerta ni color de error)
- [x] 5.4 En el mismo widget, agregar el pill/texto de consumo restante ("Quedan N hoy"), visible solo cuando `remainingToday <= 5`, en tono neutro sin usar `ReevoAccent`
- [x] 5.5 Confirmar que el estado de límite alcanzado sigue sin reportarse a Sentry (igual que hoy con `aiUsageLimitReached`)

## 6. Verificación

- [x] 6.1 `flutter analyze` sin warnings
- [x] 6.2 `flutter test` — cubrir: reset diario, chequeo/incremento atómico con la nueva firma (si hay tests de la función SQL), mapeo del nuevo `AppErrorCode`, estados nuevos del Cubit (`bloc_test`), y el widget test del bottom sheet para los 3 estados (normal, quedan pocos, límite alcanzado)
- [x] 6.3 Correr el test de español neutro (`test/unit/l10n/neutral_spanish_test.dart`) tras agregar las cadenas nuevas en `app_es.arb`
- [ ] 6.4 Verificación manual en simulador (la hace el usuario): generar resúmenes hasta ver aparecer el pill, hasta alcanzar el límite, y confirmar el estado neutro del sheet en light y dark
