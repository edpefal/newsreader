import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/navigation/route_path.dart';
import 'package:newsreader/core/widgets/cached_network_image_widget.dart';

/// Fila de un artículo referenciado por una tarjeta del resumen: miniatura,
/// título (hasta dos líneas) y chevron. Navega al detalle del artículo.
class SummaryArticleRow extends StatelessWidget {
  static const double _thumbnailSize = 40;

  final Article article;

  const SummaryArticleRow({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildFallback(BuildContext _) => ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.article_outlined,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    return InkWell(
      onTap: () => _openArticle(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: _thumbnailSize,
                height: _thumbnailSize,
                child: CachedNetworkImageWidget(
                  imageUrl: article.imageUrl,
                  width: _thumbnailSize,
                  height: _thumbnailSize,
                  placeholderBuilder: buildFallback,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _openArticle(BuildContext context) {
    final basePath = GoRouterState.of(context).uri.path;
    openDetailRoute(
      context: context,
      path: joinRoutePath(basePath, 'article/${article.id}'),
      extra: article,
      onOpened: () {},
    );
  }
}
