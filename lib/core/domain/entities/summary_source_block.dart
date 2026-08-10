import 'package:equatable/equatable.dart';

/// Agrupación por fuente usada para generar un [DailySummary]: qué
/// artículos de esa fuente se incluyeron ese día.
class SummarySourceBlock extends Equatable {
  final String sourceId;
  final String sourceName;
  final List<String> articleIds;

  const SummarySourceBlock({
    required this.sourceId,
    required this.sourceName,
    required this.articleIds,
  });

  @override
  List<Object?> get props => [sourceId, sourceName, articleIds];
}
