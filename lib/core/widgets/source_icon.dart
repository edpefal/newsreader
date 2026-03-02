import 'package:flutter/material.dart';

import 'package:newsreader/core/widgets/cached_network_image_widget.dart';

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

    Widget buildPlaceholder(BuildContext _) => CircleAvatar(
          radius: size / 2,
          child: Text(
            initial,
            style: TextStyle(fontSize: size * 0.4),
          ),
        );

    return ClipOval(
      child: CachedNetworkImageWidget(
        imageUrl: iconUrl,
        width: size,
        height: size,
        placeholderBuilder: buildPlaceholder,
      ),
    );
  }
}
