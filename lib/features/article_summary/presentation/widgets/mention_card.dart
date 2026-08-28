import 'package:flutter/material.dart';

import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/core/widgets/cached_network_image_widget.dart';
import 'package:newsreader/core/widgets/chamfered_box.dart';

/// Card de una mención dentro del bottom sheet de resumen. Una mención sin
/// `link` (libro/podcast/música sin match del proveedor, o proveedor
/// caído) se muestra como texto plano sin imagen y sin acción de tap. Una
/// mención de tipo artículo SIEMPRE tiene `link` (la URL se extrajo
/// directo del contenido, no de una búsqueda por nombre) aunque le falte
/// `imageUrl` -- ver capability `article-mentions`.
class MentionCard extends StatelessWidget {
  final EnrichedMention mention;
  final VoidCallback? onTap;

  const MentionCard({super.key, required this.mention, this.onTap});

  IconData get _placeholderIcon => switch (mention.type) {
        MentionType.book => Icons.menu_book_outlined,
        MentionType.podcast => Icons.podcasts_outlined,
        MentionType.music => Icons.music_note_outlined,
        MentionType.article => Icons.link,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = mention.imageUrl != null;

    return InkWell(
      onTap: mention.link != null ? onTap : null,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            ChamferedBox(
              chamferSize: 8,
              child: SizedBox(
                width: 88,
                height: 88,
                child: hasImage
                    ? CachedNetworkImageWidget(
                        imageUrl: mention.imageUrl,
                        width: 88,
                        height: 88,
                      )
                    : ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          _placeholderIcon,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mention.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
