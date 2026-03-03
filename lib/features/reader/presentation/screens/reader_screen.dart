import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/widgets/source_icon.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';

class ReaderScreen extends StatefulWidget {
  final Article article;
  final MarkArticleAsRead markAsRead;

  const ReaderScreen({
    super.key,
    required this.article,
    required this.markAsRead,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _isReaderMode = false;

  @override
  void initState() {
    super.initState();
    widget.markAsRead.execute(widget.article.id).ignore();
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
          IconButton(
            icon: Icon(
              _isReaderMode
                  ? Icons.chrome_reader_mode
                  : Icons.chrome_reader_mode_outlined,
            ),
            tooltip: _isReaderMode ? 'Vista original' : 'Modo Reader',
            onPressed: () => setState(() => _isReaderMode = !_isReaderMode),
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
      body: SingleChildScrollView(
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
    );
  }

  Widget _buildContent(Article article, ThemeData theme) {
    if (_isReaderMode) {
      return _buildReaderContent(article, theme);
    }
    if (article.contentHtml != null) {
      return HtmlWidget(
        article.contentHtml!,
        textStyle: theme.textTheme.bodyMedium,
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

  Widget _buildReaderContent(Article article, ThemeData theme) {
    final readerStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.7);

    final text = article.contentHtml != null
        ? _stripHtml(article.contentHtml!)
        : article.excerpt;

    if (text != null && text.isNotEmpty) {
      return Text(text, style: readerStyle);
    }
    return Text(
      'Contenido no disponible en el feed.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
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
