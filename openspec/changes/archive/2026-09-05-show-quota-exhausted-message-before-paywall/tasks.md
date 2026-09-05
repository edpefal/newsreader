## 1. Traducciones

- [x] 1.1 Agregar claves `articleSummaryFreeTierExhaustedTitle`, `articleSummaryFreeTierExhaustedSubtitle` y `articleSummaryFreeTierExhaustedButton` (o nombres equivalentes) en `lib/l10n/app_en.arb`, `app_es.arb` (español neutro, tuteo, sin voseo) y `app_fr.arb`.
- [x] 1.2 Correr `flutter gen-l10n` para regenerar `lib/l10n/app_localizations.dart`.

## 2. Cubit y estado

- [x] 2.1 Agregar el estado `ArticleSummaryFreeTierExhausted` en `article_summary_state.dart` (extiende `ArticleSummaryState`, `Equatable`, sin campos).
- [x] 2.2 Agregar el método `showFreeTierExhausted()` en `ArticleSummaryCubit` que emite ese estado sin invocar `GenerateArticleSummary` ni `AiUsageRepository`.
- [x] 2.3 Test de cubit (`bloc_test`) para `showFreeTierExhausted()`: emite únicamente `ArticleSummaryFreeTierExhausted`, sin llamar a los mocks de generación/uso.

## 3. Bottom sheet

- [x] 3.1 Agregar parámetros `bool openFreeTierExhausted = false` y `SubscriptionStatusProvider subscriptionStatusProvider` a `showArticleSummarySheet`; cuando `openFreeTierExhausted` es `true`, el `create:` del `BlocProvider` llama a `createCubit()..showFreeTierExhausted()` en vez de `..generate(article, language)`.
- [x] 3.2 Threadear `article`, `language` y `subscriptionStatusProvider` a `ArticleSummarySheetContent` para que estén disponibles en el nuevo estado.
- [x] 3.3 Agregar el caso `ArticleSummaryFreeTierExhausted()` al `switch` de `ArticleSummarySheetContent`, renderizando un nuevo widget `_FreeTierExhaustedContent` (superficie/tono neutro, igual criterio que `_LimitReachedContent`, sin color/iconografía de error) con título, subtítulo y un botón.
- [x] 3.4 El botón de `_FreeTierExhaustedContent` llama a `subscriptionStatusProvider.showPaywall(onSubscribed: ...)`; en `onSubscribed`, si `isSubscribed` es `true`, llama a `context.read<ArticleSummaryCubit>().generate(article, language)`.
- [x] 3.5 Widget tests: el sheet en estado `ArticleSummaryFreeTierExhausted` muestra el texto esperado y el botón; tocar el botón invoca `showPaywall` del mock de `SubscriptionStatusProvider`; completar la compra (invocar `onSubscribed`) dispara `generate` en el cubit.

## 4. Reader screen

- [x] 4.1 En `_onSummaryPressed`, cuando `!isSubscribed && freeStatus.limitReached`, dejar de llamar a `widget.subscriptionStatusProvider.showPaywall(...)` directo y en su lugar abrir el sheet con `openFreeTierExhausted: true` (pasando `widget.subscriptionStatusProvider` a `showArticleSummarySheet`).
- [x] 4.2 Actualizar/agregar tests de `reader_screen` para el caso "sin suscripción y sin cupo gratis": verificar que se abre el bottom sheet (no el paywall directo) al tocar el botón de resumen.

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` sin warnings.
- [x] 5.2 Correr `flutter test` (mínimo `test/unit/` y los widget tests tocados) y confirmar que todo pasa, incluida la suite `neutral_spanish_test.dart`.
