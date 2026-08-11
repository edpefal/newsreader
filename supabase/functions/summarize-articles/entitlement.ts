// Chequeo de entitlement extraído a una función pura y testeable sin
// necesitar levantar un cliente de Supabase real. `entitlements` no tiene
// fila para usuarios que nunca tuvieron suscripción -- ausencia de fila
// se trata igual que `is_active = false`, no como un caso especial.
export interface EntitlementRow {
  is_active: boolean;
}

export function hasActiveEntitlement(row: EntitlementRow | null): boolean {
  return row?.is_active === true;
}
