import 'package:equatable/equatable.dart';

import 'package:newsreader/core/domain/entities/summary_source_block.dart';

class DailySummary extends Equatable {
  final String id;
  final DateTime date;
  final String content;
  final int articleCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<SummarySourceBlock>? sourceBlocks;

  /// Instante en que el usuario abrió o descartó el resumen en el Inbox.
  final DateTime? dismissedAt;

  const DailySummary({
    required this.id,
    required this.date,
    required this.content,
    required this.articleCount,
    required this.createdAt,
    this.updatedAt,
    this.sourceBlocks,
    this.dismissedAt,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        content,
        articleCount,
        createdAt,
        updatedAt,
        sourceBlocks,
        dismissedAt,
      ];
}
