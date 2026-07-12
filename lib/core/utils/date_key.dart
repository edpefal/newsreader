import 'package:intl/intl.dart';

final _dateKeyFormat = DateFormat('yyyy-MM-dd');

/// Formatea una fecha como key natural `yyyy-MM-dd`, usada como id de
/// entidades con una única instancia por día (ej. [DailySummary]).
String dateKey(DateTime date) => _dateKeyFormat.format(date);
