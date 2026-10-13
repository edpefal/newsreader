import 'package:flutter/material.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/utils/localized_date_formatter.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_articles.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_sources.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_detail_body.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Detalle de un resumen con `AppBar` propia. Hoy solo lo usa la ruta del
/// Inbox (`/summary/:id`); la tab Resúmenes embebe [SummaryDetailBody] sin
/// chrome adicional.
class SummaryDetailScreen extends StatelessWidget {
  final DailySummary summary;
  final ResolveSummaryArticles resolveSummaryArticles;
  final ResolveSummarySources resolveSummarySources;

  /// Ver [SummaryDetailBody.onOpened].
  final VoidCallback? onOpened;

  const SummaryDetailScreen({
    super.key,
    required this.summary,
    required this.resolveSummaryArticles,
    required this.resolveSummarySources,
    this.onOpened,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.summaryDetailTitle(
            LocalizedDateFormatter.longDate(context, summary.date),
          ),
        ),
      ),
      body: SummaryDetailBody(
        summary: summary,
        resolveSummaryArticles: resolveSummaryArticles,
        resolveSummarySources: resolveSummarySources,
        onOpened: onOpened,
        showDate: false,
      ),
    );
  }
}
