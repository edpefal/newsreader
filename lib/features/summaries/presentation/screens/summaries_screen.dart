import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SummariesCubit, SummariesState>(
        builder: (context, state) {
          if (state is SummariesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final summaries = (state as SummariesLoaded).summaries;

          if (summaries.isEmpty) {
            return const _EmptySummariesState();
          }

          return ListView.builder(
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
