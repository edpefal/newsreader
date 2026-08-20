import 'package:flutter/widgets.dart';

/// Qué esquina(s) recorta [ChamferedBox]. Refleja el lenguaje visual
/// facetado del logo de Reevo en vez de un `border-radius` redondeado.
enum ChamferCorner { topRight, bottomLeft }

class ChamferedBox extends StatelessWidget {
  final Widget child;
  final double chamferSize;
  final ChamferCorner corner;

  const ChamferedBox({
    super.key,
    required this.child,
    this.chamferSize = 10,
    this.corner = ChamferCorner.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ChamferClipper(chamferSize: chamferSize, corner: corner),
      child: child,
    );
  }
}

class _ChamferClipper extends CustomClipper<Path> {
  final double chamferSize;
  final ChamferCorner corner;

  const _ChamferClipper({required this.chamferSize, required this.corner});

  @override
  Path getClip(Size size) {
    final cut = chamferSize.clamp(0, size.shortestSide / 2).toDouble();
    final path = Path();
    switch (corner) {
      case ChamferCorner.topRight:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width - cut, 0)
          ..lineTo(size.width, cut)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
      case ChamferCorner.bottomLeft:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(cut, size.height)
          ..lineTo(0, size.height - cut)
          ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(_ChamferClipper oldClipper) =>
      oldClipper.chamferSize != chamferSize || oldClipper.corner != corner;
}
