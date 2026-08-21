import 'package:flutter/material.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/utils/localized_date_formatter.dart';
import 'package:newsreader/l10n/app_localizations.dart';

class SummaryListItem extends StatelessWidget {
  final DailySummary summary;
  final VoidCallback? onTap;

  const SummaryListItem({super.key, required this.summary, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.auto_awesome_outlined),
      title: Text(
        l10n.summaryDetailTitle(
          LocalizedDateFormatter.dayLabel(context, summary.date),
        ),
      ),
      subtitle: Text(l10n.summaryListArticleCount(summary.articleCount)),
      onTap: onTap,
    );
  }
}
