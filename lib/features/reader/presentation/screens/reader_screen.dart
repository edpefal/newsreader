import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/widgets/fwh_html_content_renderer.dart';
import 'package:newsreader/core/widgets/source_icon.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/reader/domain/usecases/toggle_favorite.dart';
import 'package:newsreader/features/reader/presentation/widgets/reading_progress_bar.dart';

class ReaderScreen extends StatefulWidget {
  final Article article;
  final MarkArticleAsRead markAsRead;
  final ToggleFavorite toggleFavorite;

  const ReaderScreen({
    super.key,
    required this.article,
    required this.markAsRead,
    required this.toggleFavorite,
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

  Future<void> _onToggleFavorite() async {
    _popController.forward(from: 0);
    setState(() => _isFavorite = !_isFavorite);
    await widget.toggleFavorite.execute(widget.article.id);
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
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
              child: IconButton(
                key: ValueKey(_isFavorite),
                icon: Icon(
                  _isFavorite ? Icons.star : Icons.star_outline,
                  color: _isFavorite ? Colors.amber : null,
                ),
                tooltip:
                    _isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                onPressed: _onToggleFavorite,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Ver en navegador',
            onPressed: () => context.push(
              '/article/${article.id}/web',
              extra: article,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
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
                  _buildMeta(article),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                _buildContent(article, theme),
              ],
            ),
          ),
          ReadingProgressBar(
            progress: _scrollProgress,
            visible: _scrollBarVisible,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Article article, ThemeData theme) {
    if (article.contentHtml != null) {
      return FwhHtmlContentRenderer(
        htmlContent: article.contentHtml!,
        articleUrl: article.articleUrl,
      );
    }
    if (article.excerpt != null) {
      return Text(article.excerpt!, style: theme.textTheme.bodyMedium);
    }
    return Text(
      'Contenido no disponible en el feed.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  String _buildMeta(Article article) {
    final date = article.publishedAt;
    final dateStr = '${date.day}/${date.month}/${date.year}';
    if (article.author != null) {
      return '${article.author} · $dateStr';
    }
    return dateStr;
  }
}
