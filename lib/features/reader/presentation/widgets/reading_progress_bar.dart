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

    // Se arma con `Stack`/`Positioned` en vez de `Column`/`Expanded`: en
    // pruebas manuales en simulador de iOS (Impeller) un `Column` con
    // `Expanded` anidado dentro de este `Positioned` no llegaba a pintar
    // ningún color -- ni con contenido de alto fijo ni flexible --,
    // mientras que `Stack`/`Positioned` con `ColoredBox` pintó de forma
    // consistente en cada prueba. `LayoutBuilder` reemplaza el rol de
    // `Expanded` para repartir el alto disponible entre los segmentos.
    return AnimatedBuilder(
      animation: Listenable.merge([progress, visible]),
      builder: (context, _) {
        if (!visible.value) return const SizedBox.shrink();
        return Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: _width,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalGap = _gap * (_segmentCount - 1);
              final segmentHeight =
                  (constraints.maxHeight - totalGap) / _segmentCount;
              final value = progress.value.clamp(0.0, 1.0);
              return Stack(
                children: List.generate(_segmentCount, (index) {
                  final segmentFraction = (index + 1) / _segmentCount;
                  final isFilled = value >= segmentFraction;
                  final top = index * (segmentHeight + _gap);
                  return Positioned(
                    top: top,
                    height: segmentHeight,
                    left: 0,
                    right: 0,
                    child: ColoredBox(
                      color: isFilled ? accentColor : trackColor,
                    ),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }
}
