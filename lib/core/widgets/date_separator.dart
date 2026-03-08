import 'package:flutter/material.dart';

/// Separador de fecha para listas agrupadas por día.
/// Muestra "Hoy", "Ayer" o "d mmm." (con año si es distinto al actual).
class DateSeparator extends StatelessWidget {
  final DateTime day;

  const DateSeparator({super.key, required this.day});

  static const _months = [
    'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
    'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.',
  ];

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    final month = _months[day.month - 1];
    if (day.year != now.year) return '${day.day} $month ${day.year}';
    return '${day.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        _label(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
