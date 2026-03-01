import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'network_image_widget.dart';

class CachedNetworkImageWidget extends NetworkImageWidget {
  const CachedNetworkImageWidget({
    super.key,
    super.imageUrl,
    super.width,
    super.height,
    super.placeholderBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _buildPlaceholder(context);
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, _) => _buildPlaceholder(context),
      errorWidget: (context, _, __) => _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return placeholderBuilder?.call(context) ??
        SizedBox(width: width, height: height);
  }
}
