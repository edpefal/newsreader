import 'package:equatable/equatable.dart';

import 'package:newsreader/core/ai/mention_enricher.dart';

/// Resumen + menciones enriquecidas de un artículo individual, persistido
/// on-demand (ver capability `article-summaries`). Como máximo uno por
/// `articleId`: no hay flujo de regeneración en esta versión.
class ArticleSummary extends Equatable {
  final String articleId;
  final String summary;
  final List<EnrichedMention> mentions;
  final DateTime createdAt;

  const ArticleSummary({
    required this.articleId,
    required this.summary,
    required this.mentions,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [articleId, summary, mentions, createdAt];
}
