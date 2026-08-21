import 'package:flutter/material.dart';

import 'package:newsreader/core/utils/localized_date_formatter.dart';

/// Separador de fecha para listas agrupadas por día.
/// Muestra "Hoy", "Ayer" o "d mmm." (con año si es distinto al actual).
class DateSeparator extends StatelessWidget {
  final DateTime day;

  const DateSeparator({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        LocalizedDateFormatter.dayLabel(context, day),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
