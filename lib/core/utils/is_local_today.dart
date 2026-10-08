/// Indica si [date] (un instante, normalmente en UTC) cae en el día local de
/// [now]. Compara año/mes/día de `date.toLocal()`, así que es correcto para
/// cualquier offset horario -- incluidos los husos al este de UTC, donde la
/// clave `dateKey` (formateada en UTC) cae en el día anterior.
bool isLocalToday(DateTime date, {DateTime? now}) {
  final local = date.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  return local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
}
