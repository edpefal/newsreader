import 'package:flutter/material.dart';

/// Layout de dos paneles (lista fija a la izquierda, detalle a la derecha)
/// usado por las tabs principales en anchos "expanded" (ver
/// `WindowSizeClass`). En anchos "compact" no se usa este widget: el
/// `ShellRoute` de la branch devuelve `child` directamente para reproducir
/// el push de pantalla completa existente.
class AdaptiveListDetailScaffold extends StatelessWidget {
  final Widget list;
  final Widget detail;
  final double listWidth;

  const AdaptiveListDetailScaffold({
    super.key,
    required this.list,
    required this.detail,
    this.listWidth = 380,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: listWidth, child: list),
        const VerticalDivider(width: 1),
        Expanded(child: detail),
      ],
    );
  }
}
