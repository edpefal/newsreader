## 1. Guard en SummariesCubit

- [x] 1.1 En `SummariesCubit.generateTodaySummary` (`lib/features/summaries/presentation/cubit/summaries_cubit.dart`), envolver la llamada a `_generate(language)` dentro del callback `onSubscribed` con una re-verificación de `_subscriptionStatusProvider.isSubscribed`: si sigue siendo `false`, no invocar `_generate` ni emitir ningún estado nuevo.
- [x] 1.2 Actualizar el comentario del método para reflejar que la generación solo ocurre si la suscripción quedó efectivamente activa, no solo porque el callback de Superwall se haya ejecutado.

## 2. Tests

- [x] 2.1 Test de `SummariesCubit`: con `isSubscribed` en `false`, al llamar `generateTodaySummary`, si el mock de `showPaywall` invoca `onSubscribed` sin que `isSubscribed` haya pasado a `true` (simulando `feature_gating: non_gated` o un paywall cerrado sin comprar), el cubit no debe emitir `SummaryGenerating` ni llamar al usecase de generación.
- [x] 2.2 Test de `SummariesCubit`: con `isSubscribed` en `false`, al llamar `generateTodaySummary`, si el mock de `showPaywall` invoca `onSubscribed` después de que `isSubscribed` pasó a `true` (compra completada), el cubit sí dispara la generación normalmente (cubre el flujo existente, para evitar una regresión). Se ajustó el test existente correspondiente para que el mock actualice `isSubscribed` a `true` antes de invocar el callback -- con el guard nuevo, el mock anterior (que nunca lo actualizaba) habría hecho fallar el test.
- [x] 2.3 Confirmado: los tests existentes de `generateTodaySummary` (con suscripción ya activa desde el inicio) siguen pasando sin cambios.

## 3. Verificación

- [x] 3.1 `flutter analyze` sin warnings nuevos.
- [x] 3.2 `flutter test test/unit/features/summaries/` en verde (28/28).
- [x] 3.3 Confirmado vía `superwall get /v2/paywalls/255848`: `feature_gating: "gated"`.
