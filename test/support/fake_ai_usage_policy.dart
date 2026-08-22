import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai_usage/ai_usage_policy.dart';

/// Mock reutilizable de `AiUsagePolicy` para tests de Cubits/widgets que lo
/// reciben como dependencia. `tAiUsageStatusNotReached` cubre el caso común
/// de "consumo dentro del presupuesto", usado por defecto en la mayoría de
/// los tests existentes que no ejercitan el medidor/límite en sí.
class MockAiUsagePolicy extends Mock implements AiUsagePolicy {}

final tAiUsageStatusNotReached = AiUsageStatus(
  wordsUsed: 100,
  wordLimit: 30000,
  resetsAt: DateTime.utc(2026, 1, 2),
);
