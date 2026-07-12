import 'package:flutter/material.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';

class SummaryListItem extends StatelessWidget {
  final DailySummary summary;
  final VoidCallback? onTap;

  const SummaryListItem({super.key, required this.summary, this.onTap});

  static const _months = [
    'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
    'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.',
  ];

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'hoy';
    if (diff == 1) return 'ayer';
    final month = _months[date.month - 1];
    if (date.year != now.year) return '${date.day} $month ${date.year}';
    return '${date.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.auto_awesome_outlined),
      title: Text('Resumen del ${_formatDate(summary.date)}'),
      subtitle: Text('${summary.articleCount} artículos'),
      onTap: onTap,
    );
  }
}
