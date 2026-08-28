// Copia intencional de summarize-articles/entitlement.ts (cada Edge
// Function se despliega como unidad autocontenida, sin imports cruzados
// entre carpetas de funciones). El enriquecimiento de menciones es parte
// de la misma feature paga que el resumen de artículo (ver proposal.md),
// así que se gatea igual aunque no consuma presupuesto de IA.
export interface EntitlementRow {
  is_active: boolean;
}

export function hasActiveEntitlement(row: EntitlementRow | null): boolean {
  return row?.is_active === true;
}
