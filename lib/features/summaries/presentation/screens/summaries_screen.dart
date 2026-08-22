import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/ai_usage/ai_usage_policy.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/errors/app_error_code_localizations.dart';
import 'package:newsreader/core/utils/date_key.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_list_item.dart';
import 'package:newsreader/l10n/app_localizations.dart';

class SummariesScreen extends StatelessWidget {
  const SummariesScreen({super.key});

  @override
  Widget build(BuildContext context) => const SummariesView();
}

class SummariesView extends StatelessWidget {
  const SummariesView({super.key});

  static final _placeholderUsage = AiUsageStatus(
    wordsUsed: 0,
    wordLimit: 0,
    resetsAt: DateTime.now(),
  );

  Future<void> _onGeneratePressed(BuildContext context) async {
    final cubit = context.read<SummariesCubit>();
    final language = Localizations.localeOf(context).languageCode;

    final wouldRegenerateWithSameArticles =
        await cubit.wouldRegenerateWithSameArticles();
    if (wouldRegenerateWithSameArticles) {
      if (!context.mounted) return;
      final confirmed = await _confirmRegenerate(context);
      if (confirmed != true) return;
    }

    if (!context.mounted) return;
    await cubit.generateTodaySummary(language);
  }

  Future<bool?> _confirmRegenerate(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.summariesRegenerateConfirmTitle),
        content: Text(l10n.summariesRegenerateConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.summariesRegenerateConfirmButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: BlocBuilder<SummariesCubit, SummariesState>(
        builder: (context, state) {
          if (state is SummariesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final (summaries, canGenerateToday, isGenerating, errorMessage, usage) =
              switch (state) {
            SummariesLoaded(
              :final summaries,
              :final canGenerateToday,
              :final usage,
            ) =>
              (summaries, canGenerateToday, false, null, usage),
            SummaryGenerating(:final summaries, :final usage) => (
                summaries,
                false,
                true,
                null,
                usage,
              ),
            SummaryGenerationError(
              :final summaries,
              :final canGenerateToday,
              :final code,
              :final usage,
            ) =>
              (summaries, canGenerateToday, false, code.localize(l10n), usage),
            SummariesLoading() => (
                const <DailySummary>[],
                false,
                false,
                null,
                _placeholderUsage,
              ),
          };

          final canGenerate =
              !isGenerating && canGenerateToday && !usage.isLimitReached;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.summariesUsageMeter(usage.wordsUsed, usage.wordLimit),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: canGenerate
                          ? () => _onGeneratePressed(context)
                          : null,
                      icon: isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isGenerating
                            ? l10n.summariesGenerating
                            : summaries.any(
                                (s) => s.id == dateKey(DateTime.now()),
                              )
                                ? l10n.summariesRegenerateTodayButton
                                : l10n.summariesCreateTodayButton,
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: summaries.isEmpty
                    ? const _EmptySummariesState()
                    : ListView.builder(
                        itemCount: summaries.length,
                        itemBuilder: (context, index) {
                          final summary = summaries[index];
                          return SummaryListItem(
                            summary: summary,
                            onTap: () => context.push(
                              '/summaries/${summary.id}',
                              extra: summary,
                            ),
                          );
                        },
                      ),
              ),
            ],
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
