import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/errors/app_error_code_localizations.dart';
import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/features/article_summary/presentation/cubit/article_summary_cubit.dart';
import 'package:newsreader/features/article_summary/presentation/widgets/mention_card.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Abre el bottom sheet de resumen+menciones de [article], generándolo (o
/// mostrando el ya persistido) apenas se abre -- ver capability
/// `article-summaries`. El chequeo de suscripción/paywall ya se resolvió
/// antes de llamar a esta función (ver `ReaderScreen`).
void showArticleSummarySheet(
  BuildContext context, {
  required Article article,
  required ArticleSummaryCubit Function() createCubit,
  required ExternalLinkLauncher externalLinkLauncher,
}) {
  final language = Localizations.localeOf(context).languageCode;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider<ArticleSummaryCubit>(
      create: (_) => createCubit()..generate(article, language),
      child: ArticleSummarySheetContent(
        externalLinkLauncher: externalLinkLauncher,
      ),
    ),
  );
}

/// Contenido del bottom sheet, separado de `showArticleSummarySheet` (no
/// privado) para poder testearlo directo con un `ArticleSummaryCubit` ya
/// sembrado en un estado dado, sin pasar por `showModalBottomSheet`.
class ArticleSummarySheetContent extends StatelessWidget {
  final ExternalLinkLauncher externalLinkLauncher;

  const ArticleSummarySheetContent({super.key, required this.externalLinkLauncher});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<ArticleSummaryCubit, ArticleSummaryState>(
          builder: (context, state) {
            return switch (state) {
              ArticleSummaryLoading() => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ArticleSummaryError(:final code) => SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      code.localize(l10n),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ArticleSummaryLoaded(:final summary) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.articleSummarySheetTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(summary.summary),
                    if (summary.mentions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        l10n.articleSummaryMentionsTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 128,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: summary.mentions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final mention = summary.mentions[index];
                            return MentionCard(
                              mention: mention,
                              onTap: mention.link == null
                                  ? null
                                  : () => externalLinkLauncher.open(
                                        mention.link!,
                                      ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
            };
          },
        ),
      ),
    );
  }
}
