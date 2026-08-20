import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:newsreader/presentation/theme/app_theme.dart';

class ReadingProgressBar extends StatelessWidget {
  final ValueListenable<double> progress;
  final ValueListenable<bool> visible;

  const ReadingProgressBar({
    super.key,
    required this.progress,
    required this.visible,
  });

  static const double _width = 4;
  static const double _gap = 3;
  static const int _segmentCount = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor =
        theme.extension<ReevoAccent>()?.unreadFavoriteAmber ??
            theme.colorScheme.primary;
    final trackColor = theme.colorScheme.surfaceContainerHighest;

    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, isVisible, child) {
        if (!isVisible) return const SizedBox.shrink();
        return child!;
      },
      child: Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        width: _width,
        child: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, _) {
            return Column(
              children: List.generate(_segmentCount, (index) {
                final segmentFraction = (index + 1) / _segmentCount;
                final isFilled = value.clamp(0.0, 1.0) >= segmentFraction;
                final isLast = index == _segmentCount - 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : _gap),
                    child: ColoredBox(
                      color: isFilled ? accentColor : trackColor,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
