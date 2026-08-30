import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:newsreader/l10n/app_localizations.dart';

/// Formatea fechas según el idioma activo de la app (nombres de mes, orden
/// día/mes, y las etiquetas relativas "Hoy"/"Ayer"), reemplazando la lógica
/// de fecha que antes vivía duplicada en varios widgets con sus propios
/// arrays de meses hardcodeados en español.
class LocalizedDateFormatter {
  LocalizedDateFormatter._();

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Hoy" / "Ayer" / "15 mar." (con año si `day` no es del año actual).
  /// Usado por separadores de fecha en listas agrupadas por día.
  static String dayLabel(BuildContext context, DateTime day) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    if (_isSameDay(day, now)) return l10n.commonToday;
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(day, yesterday)) return l10n.commonYesterday;

    return day.year == now.year
        ? DateFormat.MMMd(l10n.localeName).format(day)
        : DateFormat.yMMMd(l10n.localeName).format(day);
  }

  /// Hora ("14:32") si es hoy, "Ayer" si es ayer, "{n}d" si fue esta semana,
  /// o fecha corta numérica para el resto. Usado en tiles compactos de
  /// artículo.
  static String articleTileDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final articleDay = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(articleDay).inDays;

    if (diffDays == 0) {
      return DateFormat('HH:mm', l10n.localeName).format(date);
    }
    if (diffDays == 1) return l10n.commonYesterday;
    if (diffDays < 7) return l10n.commonDaysAgoShort(diffDays);
    return DateFormat.Md(l10n.localeName).format(date);
  }

  /// Fecha con mes abreviado y año ("15 mar. 2024" / "Mar 15, 2024" /
  /// "15 mars 2024"). Usado en el Reader y Resúmenes — mismo nivel de
  /// concisión que el formato numérico que reemplaza.
  static String longDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    return DateFormat.yMMMd(l10n.localeName).format(date);
  }
}
