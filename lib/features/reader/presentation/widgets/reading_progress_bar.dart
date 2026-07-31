import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ReadingProgressBar extends StatelessWidget {
  final ValueListenable<double> progress;
  final ValueListenable<bool> visible;

  const ReadingProgressBar({
    super.key,
    required this.progress,
    required this.visible,
  });

  static const double _width = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) {
              return FractionallySizedBox(
                alignment: Alignment.topCenter,
                heightFactor: value.clamp(0.0, 1.0),
                child: ColoredBox(color: theme.colorScheme.primary),
              );
            },
          ),
        ),
      ),
    );
  }
}
