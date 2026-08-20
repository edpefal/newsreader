import 'package:flutter/material.dart';

import 'package:newsreader/core/widgets/cached_network_image_widget.dart';
import 'package:newsreader/core/widgets/chamfered_box.dart';

class SourceIcon extends StatelessWidget {
  final String? iconUrl;
  final String name;
  final double size;

  const SourceIcon({
    super.key,
    required this.iconUrl,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final theme = Theme.of(context);

    Widget buildPlaceholder(BuildContext _) => ColoredBox(
          color: theme.colorScheme.primary,
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

    return ChamferedBox(
      chamferSize: size * 0.28,
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
    );
  }
}
