import 'dart:math';

import 'package:flutter/material.dart';

/// Envuelve [child] con una textura de grano de papel muy sutil detrás.
/// El ruido es determinístico (semilla fija) para que no cambie entre
/// rebuilds ni cause jank por regenerarse en cada frame.
class PaperBackground extends StatelessWidget {
  final Widget child;

  const PaperBackground({super.key, required this.child});

  // Puntos negros de bajo alpha (light) son invisibles sobre un fondo
  // oscuro (dark), así que el color de los puntos se elige según el
  // brightness activo en vez de quedar fijo.
  static const _lightDotColor = Color(0x08000000);
  static const _darkDotColor = Color(0x14FFFFFF);

  @override
  Widget build(BuildContext context) {
    final dotColor = Theme.of(context).brightness == Brightness.dark
        ? _darkDotColor
        : _lightDotColor;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              key: const Key('paperTextureCustomPaint'),
              painter: _PaperTexturePainter(dotColor),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  static const _dotCount = 600;
  static const _seed = 42;

  final Color dotColor;

  _PaperTexturePainter(this.dotColor);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(_seed);
    final paint = Paint()..color = dotColor;
    for (var i = 0; i < _dotCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = 0.4 + random.nextDouble() * 0.6;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) =>
      dotColor != oldDelegate.dotColor;
}
