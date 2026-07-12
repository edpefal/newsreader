import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/utils/date_key.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_list_item.dart';

class SummariesScreen extends StatelessWidget {
  const SummariesScreen({super.key});

  @override
  Widget build(BuildContext context) => const SummariesView();
}

class SummariesView extends StatelessWidget {
  const SummariesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SummariesCubit, SummariesState>(
        builder: (context, state) {
          if (state is SummariesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final (summaries, canGenerateToday, isGenerating, errorMessage) =
              switch (state) {
            SummariesLoaded(:final summaries, :final canGenerateToday) => (
                summaries,
                canGenerateToday,
                false,
                null,
              ),
            SummaryGenerating(:final summaries) => (
                summaries,
                false,
                true,
                null,
              ),
            SummaryGenerationError(
              :final summaries,
              :final canGenerateToday,
              :final message,
            ) =>
              (summaries, canGenerateToday, false, message),
            SummariesLoading() => (const <DailySummary>[], false, false, null),
          };

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: isGenerating || !canGenerateToday
                          ? null
                          : () => context
                              .read<SummariesCubit>()
                              .generateTodaySummary(),
                      icon: isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isGenerating
                            ? 'Generando resumen...'
                            : summaries.any(
                                (s) => s.id == dateKey(DateTime.now()),
                              )
                                ? 'Regenerar resumen de hoy'
                                : 'Crear resumen de hoy',
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
              'Sin resúmenes todavía',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Creá el resumen de hoy para ver de qué trataron tus noticias.',
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
