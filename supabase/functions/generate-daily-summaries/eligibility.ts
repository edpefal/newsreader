// Reglas de elegibilidad para la generación automática del resumen diario
// (ver openspec/changes/add-automatic-daily-summary/specs/daily-summaries/spec.md,
// requirements "Disparo automático de la generación, sin acción del
// usuario" y "Elegibilidad: suscripción activa o lunes sin suscripción").
// Funciones puras y testeables, mismo patrón que `entitlement.ts`.

/** Desplaza [now] por [utcOffsetMinutes] para leer componentes "locales". */
function shiftToLocal(now: Date, utcOffsetMinutes: number): Date {
  return new Date(now.getTime() + utcOffsetMinutes * 60_000);
}

/**
 * `true` si la hora local actual del usuario (según su offset UTC
 * persistido) ya alcanzó [thresholdHour] (0-23), el umbral fijo de
 * generación (razonablemente temprano en la mañana local).
 */
export function isPastGenerationThreshold(
  now: Date,
  utcOffsetMinutes: number,
  thresholdHour: number,
): boolean {
  return shiftToLocal(now, utcOffsetMinutes).getUTCHours() >= thresholdHour;
}

/**
 * `true` si la fecha local actual del usuario (según su offset UTC
 * persistido) cae en lunes -- único día en que un usuario sin suscripción
 * activa es elegible.
 */
export function isMondayLocal(now: Date, utcOffsetMinutes: number): boolean {
  // Date.getUTCDay(): 0 = domingo, 1 = lunes, ..., 6 = sábado.
  return shiftToLocal(now, utcOffsetMinutes).getUTCDay() === 1;
}

/**
 * `true` si el usuario es elegible para la generación automática de hoy:
 * suscripción activa (cualquier día) o, sin suscripción, que hoy (local)
 * sea lunes.
 */
export function isEligibleToday(
  isSubscribed: boolean,
  isTodayMondayLocal: boolean,
): boolean {
  return isSubscribed || isTodayMondayLocal;
}
