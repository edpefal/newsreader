import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/entities/summary_source_block.dart';
import 'package:newsreader/core/utils/localized_date_formatter.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_articles.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Un bloque parseado de `DailySummary.content`: [title] es el nombre de
/// fuente (línea inicial del bloque) cuando se pudo identificar, `null` si
/// el bloque no sigue el formato esperado (fallback sin negrita).
class _ParsedBlock {
  final String? title;
  final String text;

  const _ParsedBlock({this.title, required this.text});
}

List<_ParsedBlock> _parseBlocks(String content) {
  final rawBlocks = content
      .trim()
      .split(RegExp(r'\n\s*\n'))
      .map((b) => b.trim())
      .where((b) => b.isNotEmpty)
      .toList();

  return rawBlocks.map((raw) {
    final newlineIndex = raw.indexOf('\n');
    if (newlineIndex == -1) return _ParsedBlock(text: raw);

    final title = raw.substring(0, newlineIndex).trim();
    final rest = raw.substring(newlineIndex + 1).trim();
    if (title.isEmpty || rest.isEmpty) return _ParsedBlock(text: raw);

    return _ParsedBlock(title: title, text: rest);
  }).toList();
}

class SummaryDetailScreen extends StatefulWidget {
  final DailySummary summary;
  final ResolveSummaryArticles resolveSummaryArticles;

  const SummaryDetailScreen({
    super.key,
    required this.summary,
    required this.resolveSummaryArticles,
  });

  @override
  State<SummaryDetailScreen> createState() => _SummaryDetailScreenState();
}

class _SummaryDetailScreenState extends State<SummaryDetailScreen> {
  Map<String, Article> _resolvedArticles = const {};

  @override
  void initState() {
    super.initState();
    _resolveArticles();
  }

  Future<void> _resolveArticles() async {
    final blocks = widget.summary.sourceBlocks;
    if (blocks == null || blocks.isEmpty) return;

    final allIds = blocks.expand((b) => b.articleIds).toList();
    final resolved = await widget.resolveSummaryArticles.execute(allIds);
    if (mounted) setState(() => _resolvedArticles = resolved);
  }

  SummarySourceBlock? _matchingSourceBlock(String title) {
    final blocks = widget.summary.sourceBlocks;
    if (blocks == null) return null;
    for (final block in blocks) {
      if (block.sourceName.trim() == title) return block;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(widget.summary.content);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.summaryDetailTitle(
            LocalizedDateFormatter.longDate(context, widget.summary.date),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.summaryDetailArticleCount(widget.summary.articleCount),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            for (final block in blocks)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _SummaryBlockView(
                  block: block,
                  sourceBlock: block.title == null
                      ? null
                      : _matchingSourceBlock(block.title!),
                  resolvedArticles: _resolvedArticles,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBlockView extends StatelessWidget {
  final _ParsedBlock block;
  final SummarySourceBlock? sourceBlock;
  final Map<String, Article> resolvedArticles;

  const _SummaryBlockView({
    required this.block,
    required this.sourceBlock,
    required this.resolvedArticles,
  });

  @override
  Widget build(BuildContext context) {
    final articles = sourceBlock == null
        ? const <Article>[]
        : sourceBlock!.articleIds
            .map((id) => resolvedArticles[id])
            .whereType<Article>()
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title != null) ...[
          Text(
            block.title!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
        ],
        Text(block.text, style: Theme.of(context).textTheme.bodyLarge),
        if (articles.length == 1) ...[
          const SizedBox(height: 8),
          _ArticleLink(article: articles.first),
        ] else if (articles.length > 1) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final article in articles) _ArticleChip(article: article),
            ],
          ),
        ],
      ],
    );
  }
}

class _ArticleLink extends StatelessWidget {
  final Article article;

  const _ArticleLink({required this.article});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => context.push('/article/${article.id}', extra: article),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_new, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              article.title,
              style: TextStyle(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleChip extends StatelessWidget {
  final Article article;

  const _ArticleChip({required this.article});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Text(
          article.title,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      onPressed: () => context.push('/article/${article.id}', extra: article),
    );
  }
}
