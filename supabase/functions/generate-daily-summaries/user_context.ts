// Resolución de valores por usuario a partir de filas de Postgres,
// extraída a funciones puras y testeables (mismo patrón que
// `entitlement.ts`/`eligibility.ts`) en vez de dejarlas inline en
// `index.ts`.

export interface UserPreferenceRow {
  locale: string | null;
  utc_offset_minutes: number | null;
}

/**
 * Offset horario UTC (minutos) a usar para un usuario. Sin preferencia
 * sincronizada todavía (fila `null`) o sin valor persistido, cae a UTC+0
 * (ver capability `user-preferences`, requirement "Valor por defecto antes
 * de la primera sincronización").
 */
export function resolveUtcOffsetMinutes(
  pref: UserPreferenceRow | null,
): number {
  return pref?.utc_offset_minutes ?? 0;
}

/**
 * `true` si ya existe un `DailySummary` para la fecha local de hoy de un
 * usuario (idempotencia: ver requirement "Un único resumen por día, sin
 * regeneración") -- la generación se omite en ese caso, sin invocar a
 * Gemini ni sobreescribir nada.
 */
export function hasSummaryForToday(
  existingSummaryRow: { id: string } | null,
): boolean {
  return existingSummaryRow !== null;
}
