import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/observability/telemetry_client.dart';

/// Mock reutilizable de `TelemetryClient` para tests de Cubits/usecases
/// que lo reciben como dependencia nueva. No requiere `registerFallbackValue`
/// para sus métodos porque `captureException`/`captureMessage`/`addBreadcrumb`
/// no se comparan por igualdad en los tests existentes, solo se verifica que
/// fueron llamados.
class MockTelemetryClient extends Mock implements TelemetryClient {}
