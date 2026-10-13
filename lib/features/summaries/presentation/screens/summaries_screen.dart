import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_articles.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_sources.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_detail_body.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Raíz de la tab Resúmenes: el resumen más reciente directamente, sin lista
/// (los anteriores ya no son accesibles), o un estado vacío si aún no hay.
class SummariesScreen extends StatelessWidget {
  final ResolveSummaryArticles resolveSummaryArticles;
  final ResolveSummarySources resolveSummarySources;

  /// Se invoca con el id del resumen mostrado al montarse (descarta la
  /// tarjeta de hoy del Inbox sin que este feature conozca al de Inbox).
  final void Function(String summaryId)? onSummaryOpened;

  const SummariesScreen({
    super.key,
    required this.resolveSummaryArticles,
    required this.resolveSummarySources,
    this.onSummaryOpened,
  });

  @override
  Widget build(BuildContext context) => SummariesView(
        resolveSummaryArticles: resolveSummaryArticles,
        resolveSummarySources: resolveSummarySources,
        onSummaryOpened: onSummaryOpened,
      );
}

class SummariesView extends StatelessWidget {
  final ResolveSummaryArticles resolveSummaryArticles;
  final ResolveSummarySources resolveSummarySources;
  final void Function(String summaryId)? onSummaryOpened;

  const SummariesView({
    super.key,
    required this.resolveSummaryArticles,
    required this.resolveSummarySources,
    this.onSummaryOpened,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SummariesCubit, SummariesState>(
        builder: (context, state) {
          if (state is SummariesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = (state as SummariesLoaded).summary;
          if (summary == null) return const _EmptySummariesState();

          return SummaryDetailBody(
            key: ValueKey(summary.id),
            summary: summary,
            resolveSummaryArticles: resolveSummaryArticles,
            resolveSummarySources: resolveSummarySources,
            onOpened: () => onSummaryOpened?.call(summary.id),
          );
        },
      ),
    );
  }
}

class _EmptySummariesState extends StatelessWidget {
  const _EmptySummariesState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.summariesEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.summariesEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
