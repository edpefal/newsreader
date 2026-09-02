// Límite de "día de servidor" usado para el gate de una generación por día
// (ver limit-daily-summary-to-once-per-day) -- extraído a una función pura y
// testeable sin necesitar levantar un cliente de Supabase real, mismo
// patrón que entitlement.ts.
export interface UtcDayRange {
  start: Date;
  end: Date;
}

export function todayUtcRange(now: Date): UtcDayRange {
  const start = new Date(Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate(),
  ));
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return { start, end };
}
