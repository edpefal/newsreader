import 'package:newsreader/core/domain/entities/daily_summary.dart';

abstract class SummaryRepository {
  Future<List<DailySummary>> getAll();
  Future<void> save(DailySummary summary);
  Future<DailySummary?> getByDate(DateTime date);

  /// Busca un resumen por su `id`, o `null` si no existe.
  Future<DailySummary?> getById(String id);

  /// Marca el resumen [id] como descartado del Inbox. Idempotente: devuelve el
  /// resumen actualizado, o `null` si no existe o ya estaba descartado.
  Future<DailySummary?> dismiss(String id);

  /// Emite la lista completa de resúmenes cada vez que cambia el almacenamiento
  /// local (otra tab, sync).
  Stream<List<DailySummary>> watchAll();
}
