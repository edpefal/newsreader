import 'dart:math';

import 'package:flutter/material.dart';

/// Envuelve [child] con una textura de grano de papel muy sutil detrás.
/// El ruido es determinístico (semilla fija) para que no cambie entre
/// rebuilds ni cause jank por regenerarse en cada frame.
class PaperBackground extends StatelessWidget {
  final Widget child;

  const PaperBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _PaperTexturePainter()),
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

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(_seed);
    final paint = Paint()..color = const Color(0x08000000);
    for (var i = 0; i < _dotCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = 0.4 + random.nextDouble() * 0.6;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) => false;
}
