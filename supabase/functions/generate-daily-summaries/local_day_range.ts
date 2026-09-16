// Rango de un día en UTC, adaptado a la zona horaria local de un usuario
// (ver capability `user-preferences`) -- extraído a una función pura y
// testeable sin necesitar levantar un cliente de Supabase real, mismo
// patrón que `entitlement.ts`. Reemplaza a `today_range.ts` de
// `summarize-articles` (día de SERVIDOR, sin noción de usuario): acá cada
// usuario tiene su propio offset UTC persistido, no timezone IANA (se
// acepta la imprecisión de DST como trade-off, ver design.md).
export interface UtcDayRange {
  start: Date;
  end: Date;
}

/**
 * Rango UTC que corresponde al día local de un usuario con offset horario
 * [utcOffsetMinutes] respecto a UTC, evaluado en el instante [now].
 *
 * No usa timezone IANA: simplemente desplaza [now] por el offset en
 * minutos para leer los componentes de fecha "locales", y vuelve a
 * desplazar el resultado a un instante UTC real.
 */
export function localDayRange(
  now: Date,
  utcOffsetMinutes: number,
): UtcDayRange {
  const shifted = new Date(now.getTime() + utcOffsetMinutes * 60_000);
  const localMidnightShifted = new Date(Date.UTC(
    shifted.getUTCFullYear(),
    shifted.getUTCMonth(),
    shifted.getUTCDate(),
  ));
  const start = new Date(
    localMidnightShifted.getTime() - utcOffsetMinutes * 60_000,
  );
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return { start, end };
}

/** Caso particular de [localDayRange] para offset 0 (día de servidor/UTC). */
export function todayUtcRange(now: Date): UtcDayRange {
  return localDayRange(now, 0);
}
