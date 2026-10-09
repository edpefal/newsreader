import 'package:flutter/material.dart';

import 'package:newsreader/core/theme/reevo_accent.dart';
import 'package:newsreader/core/widgets/cached_network_image_widget.dart';

/// Avatar redondo de una fuente, pensado para apilarse en la cabecera del
/// resumen. El borde usa el color de fondo para marcar el solapamiento.
class SummarySourceAvatar extends StatelessWidget {
  static const double size = 34;

  final String? iconUrl;
  final String name;

  const SummarySourceAvatar({
    super.key,
    required this.iconUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    Widget buildPlaceholder(BuildContext _) => ColoredBox(
      color:
          theme.extension<ReevoAccent>()?.unreadFavoriteAccent ??
          theme.colorScheme.primary,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImageWidget(
            imageUrl: iconUrl,
            width: size,
            height: size,
            placeholderBuilder: buildPlaceholder,
          ),
        ),
      ),
    );
  }
}
