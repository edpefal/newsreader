// Resuelve el límite diario vigente para `check_and_record_ai_usage` según
// el estado de suscripción, extraído a una función pura y testeable, mismo
// patrón que `hasActiveEntitlement` en entitlement.ts (ver capability
// `ai-usage-budget`, requirement "Límite diario de resúmenes de artículo
// por usuario").
export const AI_DAILY_SUMMARY_LIMIT = 25;
export const AI_FREE_TIER_DAILY_LIMIT = 2;

export function resolveDailyLimit(isSubscribed: boolean): number {
  return isSubscribed ? AI_DAILY_SUMMARY_LIMIT : AI_FREE_TIER_DAILY_LIMIT;
}
