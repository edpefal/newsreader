import 'package:flutter/material.dart';

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
            SourceIcon(iconUrl: article.sourceIconUrl, name: article.sourceName, size: 24),
            Expanded(
              child: Text(
                article.sourceName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
            if (article.excerpt != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                article.excerpt!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
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
