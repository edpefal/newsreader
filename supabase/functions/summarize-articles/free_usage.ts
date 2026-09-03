// Chequeo del cupo gratis semanal extraído a una función pura y testeable,
// mismo patrón que `hasActiveEntitlement` en entitlement.ts. La ausencia de
// fila en `daily_summary_free_usage` (RPC `get_daily_summary_free_usage_status`
// nunca devuelve null en la práctica -- siempre hace upsert antes de leer,
// pero se trata `null`/`undefined` igual que `used = false` por
// robustez, mismo criterio que `hasActiveEntitlement` con `entitlements`).
export interface DailySummaryFreeUsageRow {
  used: boolean;
}

export function hasFreeUsageAvailable(
  row: DailySummaryFreeUsageRow | null | undefined,
): boolean {
  return row?.used !== true;
}
