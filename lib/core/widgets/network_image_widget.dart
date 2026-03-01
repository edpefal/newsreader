import 'package:flutter/widgets.dart';

abstract class NetworkImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context)? placeholderBuilder;

  const NetworkImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.placeholderBuilder,
  });
}
