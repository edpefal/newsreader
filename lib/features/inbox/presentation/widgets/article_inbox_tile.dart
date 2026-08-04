import 'package:flutter/material.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/widgets/cached_network_image_widget.dart';
import 'package:newsreader/core/widgets/source_icon.dart';

class ArticleInboxTile extends StatelessWidget {
  static const double _thumbnailSize = 56;

  final Article article;
  final VoidCallback? onTap;

  const ArticleInboxTile({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SourceIcon(
        iconUrl: article.sourceIconUrl,
        name: article.sourceName,
      ),
      title: Text(
        article.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${article.sourceName} · ${_formatDate(article.publishedAt)}',
      ),
      trailing: article.imageUrl == null ? null : _buildThumbnail(),
      onTap: onTap,
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImageWidget(
        imageUrl: article.imageUrl,
        width: _thumbnailSize,
        height: _thumbnailSize,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final articleDay = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(articleDay).inDays;

    if (diffDays == 0) {
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diffDays == 1) {
      return 'Ayer';
    } else if (diffDays < 7) {
      return '${diffDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
