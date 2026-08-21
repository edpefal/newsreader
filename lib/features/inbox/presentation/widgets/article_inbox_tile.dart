import 'package:flutter/material.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/utils/localized_date_formatter.dart';
import 'package:newsreader/core/widgets/cached_network_image_widget.dart';
import 'package:newsreader/core/widgets/chamfered_box.dart';
import 'package:newsreader/core/widgets/source_icon.dart';
import 'package:newsreader/presentation/theme/app_theme.dart';

class ArticleInboxTile extends StatelessWidget {
  static const double _thumbnailSize = 56;

  final Article article;
  final VoidCallback? onTap;

  const ArticleInboxTile({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.extension<ReevoAccent>();

    return ListTile(
      leading: SourceIcon(
        iconUrl: article.sourceIconUrl,
        name: article.sourceName,
      ),
      title: Text(
        article.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: article.isRead ? FontWeight.w500 : FontWeight.w600,
          color: article.isRead
              ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Row(
        children: [
          if (!article.isRead && accent != null) ...[
            _UnreadChamfer(color: accent.unreadFavoriteAmber),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              '${article.sourceName} · '
              '${LocalizedDateFormatter.articleTileDate(context, article.publishedAt)}',
              style: theme.textTheme.labelMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: _buildTrailing(accent),
      onTap: onTap,
    );
  }

  Widget? _buildTrailing(ReevoAccent? accent) {
    final isFavoriteVisible = article.isFavorite && accent != null;

    if (article.imageUrl == null) {
      return isFavoriteVisible
          ? Icon(Icons.star, size: 18, color: accent.unreadFavoriteAmber)
          : null;
    }

    if (!isFavoriteVisible) return _buildThumbnail();

    // La estrella se superpone como badge sobre la esquina del thumbnail
    // (no se apila debajo) para no exceder el alto del ListTile.
    return SizedBox(
      width: _thumbnailSize,
      height: _thumbnailSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildThumbnail(),
          Positioned(
            bottom: -4,
            right: -4,
            child: Icon(
              Icons.star,
              size: 18,
              color: accent.unreadFavoriteAmber,
              shadows: const [
                Shadow(blurRadius: 3, color: Colors.black45),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return ChamferedBox(
      chamferSize: 12,
      child: CachedNetworkImageWidget(
        imageUrl: article.imageUrl,
        width: _thumbnailSize,
        height: _thumbnailSize,
      ),
    );
  }

}

/// Mini-chaflán que marca un artículo como no leído, en el acento ámbar
/// reservado para este uso (ver [ReevoAccent]).
class _UnreadChamfer extends StatelessWidget {
  final Color color;

  const _UnreadChamfer({required this.color});

  @override
  Widget build(BuildContext context) {
    return ChamferedBox(
      chamferSize: 3,
      child: ColoredBox(
        color: color,
        child: const SizedBox(width: 8, height: 8),
      ),
    );
  }
}
