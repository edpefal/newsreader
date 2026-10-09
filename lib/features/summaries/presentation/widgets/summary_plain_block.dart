import 'package:flutter/material.dart';

/// Bloque de resumen sin tarjeta: título de fuente en negrita (si lo hay) y
/// texto. Se usa cuando el resumen no tiene agrupación por fuente o el bloque
/// no empareja con ninguna.
class SummaryPlainBlock extends StatelessWidget {
  final String? title;
  final String text;

  const SummaryPlainBlock({super.key, this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
        ],
        Text(text, style: textTheme.bodyLarge),
      ],
    );
  }
}
