import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/errors/app_error_code_localizations.dart';
import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/features/article_summary/presentation/cubit/article_summary_cubit.dart';
import 'package:newsreader/features/article_summary/presentation/widgets/mention_card.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Abre el bottom sheet de resumen+menciones de [article], generándolo (o
/// mostrando el ya persistido) apenas se abre -- ver capability
/// `article-summaries`. El chequeo de suscripción/cupo gratis ya se
/// resolvió antes de llamar a esta función (ver `ReaderScreen`).
///
/// Cuando [openFreeTierExhausted] es `true` (usuario sin suscripción activa
/// y sin cupo diario gratis disponible), el sheet arranca directo en el
/// estado de cupo agotado en vez de intentar generar -- ver
/// `ArticleSummaryCubit.showFreeTierExhausted`.
void showArticleSummarySheet(
  BuildContext context, {
  required Article article,
  required ArticleSummaryCubit Function() createCubit,
  required ExternalLinkLauncher externalLinkLauncher,
  required SubscriptionStatusProvider subscriptionStatusProvider,
  bool openFreeTierExhausted = false,
}) {
  final language = Localizations.localeOf(context).languageCode;
  // Tope de alto explícito: sin esto, un resumen largo dentro del
  // `SingleChildScrollView` de `ArticleSummarySheetContent` hace crecer el
  // sheet hasta tapar el status bar (ver fix de REEVO-PROD-8 y su
  // regresión). Se resta el inset superior seguro (notch/status bar) más
  // un margen chico, para que el sheet nunca lo cubra sin importar cuán
  // largo sea el contenido -- el `SingleChildScrollView` interno se encarga
  // de que el contenido que no entra en ese alto scrollee, en vez de
  // desbordar ni de empujar el sheet más allá de este tope.
  final maxHeight =
      MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top - 24;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: maxHeight),
    builder: (sheetContext) => BlocProvider<ArticleSummaryCubit>(
      create: (_) {
        final cubit = createCubit();
        if (openFreeTierExhausted) {
          cubit.showFreeTierExhausted();
        } else {
          cubit.generate(article, language);
        }
        return cubit;
      },
      child: ArticleSummarySheetContent(
        article: article,
        language: language,
        externalLinkLauncher: externalLinkLauncher,
        subscriptionStatusProvider: subscriptionStatusProvider,
      ),
    ),
  );
}

/// Contenido del bottom sheet, separado de `showArticleSummarySheet` (no
/// privado) para poder testearlo directo con un `ArticleSummaryCubit` ya
/// sembrado en un estado dado, sin pasar por `showModalBottomSheet`.
class ArticleSummarySheetContent extends StatelessWidget {
  final Article article;
  final String language;
  final ExternalLinkLauncher externalLinkLauncher;
  final SubscriptionStatusProvider subscriptionStatusProvider;

  const ArticleSummarySheetContent({
    super.key,
    required this.article,
    required this.language,
    required this.externalLinkLauncher,
    required this.subscriptionStatusProvider,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        // `showModalBottomSheet` no scrollea su contenido por sí solo: un
        // resumen largo (hasta 4 párrafos, ver capability `article-summaries`)
        // más el carrusel de menciones puede superar el alto disponible del
        // sheet y desbordar (ver REEVO-PROD-8). `SingleChildScrollView`
        // deja que el contenido scrollee en vez de desbordar, sin afectar
        // los casos cortos (Loading/Error/LimitReached).
        child: SingleChildScrollView(
          child: BlocBuilder<ArticleSummaryCubit, ArticleSummaryState>(
            builder: (context, state) {
              return switch (state) {
                ArticleSummaryLoading() => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                ArticleSummaryLimitReached(:final dailyLimit) =>
                  _LimitReachedContent(l10n: l10n, dailyLimit: dailyLimit),
                ArticleSummaryFreeTierExhausted() => _FreeTierExhaustedContent(
                  l10n: l10n,
                  article: article,
                  language: language,
                  subscriptionStatusProvider: subscriptionStatusProvider,
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
                ArticleSummaryLoaded(:final summary, :final remainingToday) =>
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.articleSummarySheetTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (remainingToday != null)
                            _RemainingPill(remaining: remainingToday),
                        ],
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
      ),
    );
  }
}

/// Indicador sutil de consumo diario, siempre visible. Tono neutro a
/// propósito: nunca usa `ReevoAccent` (el ámbar está reservado para
/// no-leído/favorito) -- ver design.md.
class _RemainingPill extends StatelessWidget {
  final int remaining;

  const _RemainingPill({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        l10n.articleSummaryRemainingToday(remaining),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Estado propio para el límite diario alcanzado -- superficie y tono
/// neutro (paper/ink en light, dark surface/on-surface en dark), sin el
/// color ni la iconografía de error genérico: no es una falla, es un tope
/// esperado por diseño (ver ArticleSummaryLimitReached).
class _LimitReachedContent extends StatelessWidget {
  final AppLocalizations l10n;
  final int dailyLimit;

  const _LimitReachedContent({required this.l10n, required this.dailyLimit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.articleSummaryLimitReachedTitle(dailyLimit),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.articleSummaryLimitReachedSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado propio para el usuario sin suscripción activa que ya agotó su
/// cupo diario gratis -- mismo criterio de superficie/tono neutro que
/// `_LimitReachedContent` (ver ArticleSummaryFreeTierExhausted), con un
/// botón que dispara el paywall en vez de mostrarlo automáticamente.
class _FreeTierExhaustedContent extends StatelessWidget {
  final AppLocalizations l10n;
  final Article article;
  final String language;
  final SubscriptionStatusProvider subscriptionStatusProvider;

  const _FreeTierExhaustedContent({
    required this.l10n,
    required this.article,
    required this.language,
    required this.subscriptionStatusProvider,
  });

  Future<void> _onUpgradePressed(BuildContext context) async {
    final cubit = context.read<ArticleSummaryCubit>();
    await subscriptionStatusProvider.showPaywall(
      onSubscribed: () async {
        if (!subscriptionStatusProvider.isSubscribed) return;
        cubit.generate(article, language);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.articleSummaryFreeTierExhaustedTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.articleSummaryFreeTierExhaustedSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _onUpgradePressed(context),
              child: Text(l10n.articleSummaryFreeTierExhaustedButton),
            ),
          ],
        ),
      ),
    );
  }
}
