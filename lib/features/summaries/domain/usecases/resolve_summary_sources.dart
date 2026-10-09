import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';

/// Resuelve las fuentes referenciadas por un [DailySummary.sourceBlocks],
/// descartando en silencio los ids que ya no correspondan a ninguna fuente
/// local (ej. fue eliminada después de generar el resumen).
class ResolveSummarySources {
  final SourceRepository _sourceRepository;

  const ResolveSummarySources(this._sourceRepository);

  Future<Map<String, NewsSource>> execute(List<String> sourceIds) async {
    final result = <String, NewsSource>{};
    for (final id in sourceIds) {
      final source = await _sourceRepository.getSourceById(id);
      if (source != null) result[id] = source;
    }
    return result;
  }
}
