// Resuelve a qué usuarios afecta un evento de RevenueCat.
// Un evento normal trae `app_user_id`. `TRANSFER` (traspaso de transacciones
// y entitlements entre usuarios) no lo trae: identifica a los usuarios en
// `transferred_from` y `transferred_to`, y se manda una sola vez, para el
// usuario destino. La detección se basa en la forma del payload y no en el
// valor de `type`.
// Ver openspec/changes/handle-revenuecat-transfer-events/design.md (D1, D4).

/** Tope de usuarios por evento: un traspaso real involucra a muy pocos. */
export const MAX_EVENT_USERS = 20;

export interface EventUsers {
  userIds: string[];
  /** Había más identificadores que el tope y se descartaron los sobrantes. */
  truncated: boolean;
}

function stringsOf(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string =>
    typeof item === "string" && item.length > 0
  );
}

export function resolveEventUsers(
  event: unknown,
  max: number = MAX_EVENT_USERS,
): EventUsers {
  if (typeof event !== "object" || event === null) {
    return { userIds: [], truncated: false };
  }
  const fields = event as Record<string, unknown>;

  const appUserId = fields.app_user_id;
  if (typeof appUserId === "string" && appUserId.length > 0) {
    return { userIds: [appUserId], truncated: false };
  }

  const unique = [
    ...new Set([
      ...stringsOf(fields.transferred_from),
      ...stringsOf(fields.transferred_to),
    ]),
  ];
  return { userIds: unique.slice(0, max), truncated: unique.length > max };
}
