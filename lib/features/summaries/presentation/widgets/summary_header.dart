import 'package:flutter/material.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_source_avatar.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Cabecera del detalle: avatares apilados de las fuentes y "N artículos de M
/// fuentes". Sin agrupación por fuente solo muestra el conteo de artículos.
class SummaryHeader extends StatelessWidget {
  static const int _maxAvatars = 4;

  final DailySummary summary;
  final Map<String, NewsSource> sources;

  const SummaryHeader({
    super.key,
    required this.summary,
    required this.sources,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final blocks = summary.sourceBlocks;

    if (blocks == null || blocks.isEmpty) {
      return Text(
        l10n.summaryDetailArticleCount(summary.articleCount),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final shown = blocks.take(_maxAvatars).toList();
    final extra = blocks.length - shown.length;

    const step = 24.0;
    final slots = shown.length + (extra > 0 ? 1 : 0);

    return Row(
      children: [
        SizedBox(
          width: step * (slots - 1) + SummarySourceAvatar.size,
          height: SummarySourceAvatar.size,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: step * i,
                  child: SummarySourceAvatar(
                    iconUrl: sources[shown[i].sourceId]?.iconUrl,
                    name: shown[i].sourceName,
                  ),
                ),
              if (extra > 0)
                Positioned(
                  left: step * shown.length,
                  child: _ExtraAvatar(count: extra),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.summaryDetailHeaderCount(summary.articleCount, blocks.length),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExtraAvatar extends StatelessWidget {
  final int count;

  const _ExtraAvatar({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
      ),
      child: SizedBox(
        width: SummarySourceAvatar.size,
        height: SummarySourceAvatar.size,
        child: Center(
          child: Text(
            '+$count',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
