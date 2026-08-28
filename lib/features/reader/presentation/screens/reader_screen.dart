import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/core/navigation/route_path.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/core/utils/feed_content_checker.dart';
import 'package:newsreader/core/utils/localized_date_formatter.dart';
import 'package:newsreader/core/widgets/chamfered_box.dart';
import 'package:newsreader/core/widgets/fwh_html_content_renderer.dart';
import 'package:newsreader/core/widgets/paper_texture.dart';
import 'package:newsreader/core/widgets/source_icon.dart';
import 'package:newsreader/features/article_summary/presentation/cubit/article_summary_cubit.dart';
import 'package:newsreader/features/article_summary/presentation/widgets/article_summary_bottom_sheet.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/reader/domain/usecases/toggle_favorite.dart';
import 'package:newsreader/features/reader/presentation/widgets/reading_progress_bar.dart';
import 'package:newsreader/l10n/app_localizations.dart';
import 'package:newsreader/presentation/theme/app_theme.dart';

/// Ancho máximo del cuerpo del artículo (título, metadata y HTML) para una
/// línea de lectura cómoda en pantallas anchas (ver capability
/// `reader-typography`).
const double kReaderMaxContentWidth = 680;

/// Centra [child] con un ancho máximo de [kReaderMaxContentWidth], sin
/// afectar el ancho de las pantallas más angostas que ese máximo.
class _MaxWidthCentered extends StatelessWidget {
  final Widget child;

  const _MaxWidthCentered({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kReaderMaxContentWidth),
        child: child,
      ),
    );
  }
}

class ReaderScreen extends StatefulWidget {
  final Article article;
  final MarkArticleAsRead markAsRead;
  final ToggleFavorite toggleFavorite;
  final SubscriptionStatusProvider subscriptionStatusProvider;
  final ArticleSummaryCubit Function() createArticleSummaryCubit;
  final ExternalLinkLauncher externalLinkLauncher;

  const ReaderScreen({
    super.key,
    required this.article,
    required this.markAsRead,
    required this.toggleFavorite,
    required this.subscriptionStatusProvider,
    required this.createArticleSummaryCubit,
    required this.externalLinkLauncher,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late bool _isFavorite;
  late AnimationController _popController;
  late Animation<double> _popScale;
  final _scrollController = ScrollController();
  final _scrollProgress = ValueNotifier<double>(0);
  final _scrollBarVisible = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.article.isFavorite;
    widget.markAsRead.execute(widget.article.id).ignore();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _popController, curve: Curves.easeOut));
    _scrollController.addListener(_updateScrollProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollProgress());
  }

  @override
  void dispose() {
    _popController.dispose();
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.dispose();
    _scrollProgress.dispose();
    _scrollBarVisible.dispose();
    super.dispose();
  }

  void _updateScrollProgress() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    _scrollBarVisible.value = maxExtent > 0;
    _scrollProgress.value = maxExtent > 0
        ? (position.pixels / maxExtent).clamp(0.0, 1.0)
        : 0;
  }

  /// Navega al WebView del artículo con una ruta relativa a la ubicación
  /// actual (`.../web`), para funcionar sin importar bajo qué branch
  /// (Inbox, Favoritos, Archivo, Fuentes, Resúmenes) esté anidada la ruta
  /// de este lector.
  void _openWebView(BuildContext context, Article article) {
    final currentPath = GoRouterState.of(context).uri.path;
    context.push(joinRoutePath(currentPath, 'web'), extra: article);
  }

  Future<void> _onToggleFavorite() async {
    _popController.forward(from: 0);
    setState(() => _isFavorite = !_isFavorite);
    await widget.toggleFavorite.execute(widget.article.id);
  }

  /// Mismo patrón que `SummariesView`: si no hay suscripción activa,
  /// muestra el paywall antes de abrir el bottom sheet, y vuelve a chequear
  /// `isSubscribed` tras su cierre en vez de confiar únicamente en que
  /// Superwall haya invocado el callback de compra completada.
  Future<void> _onSummaryPressed(BuildContext context) async {
    if (!widget.subscriptionStatusProvider.isSubscribed) {
      await widget.subscriptionStatusProvider.showPaywall(
        onSubscribed: () async {
          if (!widget.subscriptionStatusProvider.isSubscribed) return;
          if (!mounted) return;
          _openSummarySheet(context);
        },
      );
      return;
    }
    _openSummarySheet(context);
  }

  void _openSummarySheet(BuildContext context) {
    showArticleSummarySheet(
      context,
      article: widget.article,
      createCubit: widget.createArticleSummaryCubit,
      externalLinkLauncher: widget.externalLinkLauncher,
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final theme = Theme.of(context);
    final accent = theme.extension<ReevoAccent>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const ChamferedBox(chamferSize: 6, child: BackButton()),
        title: Row(
          spacing: 8,
          children: [
            SourceIcon(
              iconUrl: article.sourceIconUrl,
              name: article.sourceName,
              size: 24,
            ),
            Expanded(
              child: Text(
                article.sourceName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _popScale,
            builder: (context, child) =>
                Transform.scale(scale: _popScale.value, child: child),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: ChamferedBox(
                key: ValueKey(_isFavorite),
                chamferSize: 6,
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_outline,
                    color: _isFavorite ? accent?.unreadFavoriteAmber : null,
                  ),
                  tooltip: _isFavorite
                      ? l10n.readerRemoveFavoriteTooltip
                      : l10n.readerAddFavoriteTooltip,
                  onPressed: _onToggleFavorite,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: l10n.readerOpenInBrowserTooltip,
            onPressed: () => _openWebView(context, article),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: l10n.articleSummaryButtonTooltip,
            onPressed: () => _onSummaryPressed(context),
          ),
        ],
      ),
      body: PaperBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MaxWidthCentered(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _buildMeta(context, article),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // El contenido raw de email queda exento del ancho máximo
                  // de lectura: se renderiza en un WebView aislado que ya
                  // resuelve su propio layout (ver `looksLikeRawEmailHtml`).
                  _isRawEmailArticle(article)
                      ? _buildContent(context, article, theme)
                      : _MaxWidthCentered(
                          child: _buildContent(context, article, theme),
                        ),
                ],
              ),
            ),
            ReadingProgressBar(
              progress: _scrollProgress,
              visible: _scrollBarVisible,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Article article, ThemeData theme) {
    final children = <Widget>[];

    if (article.contentHtml != null) {
      children.add(FwhHtmlContentRenderer(
        htmlContent: article.contentHtml!,
        articleUrl: article.articleUrl,
        readerMode: true,
      ));
    } else if (article.excerpt != null) {
      children.add(Text(article.excerpt!, style: theme.textTheme.bodyMedium));
    }

    if (FeedContentChecker.isTruncated(article.contentHtml)) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 16));
      children.add(_buildTruncatedHint(context, article, theme));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildTruncatedHint(
    BuildContext context,
    Article article,
    ThemeData theme,
  ) {
    final color = theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: () => _openWebView(context, article),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.public, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).readerTruncatedContentHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isRawEmailArticle(Article article) {
    final html = article.contentHtml;
    return html != null && looksLikeRawEmailHtml(html);
  }

  String _buildMeta(BuildContext context, Article article) {
    final dateStr = LocalizedDateFormatter.longDate(
      context,
      article.publishedAt,
    );
    if (article.author != null) {
      return '${article.author} · $dateStr';
    }
    return dateStr;
  }
}
