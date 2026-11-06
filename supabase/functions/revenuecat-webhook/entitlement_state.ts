// Consulta a RevenueCat si el entitlement `pro` de un usuario está vigente.
// El webhook y `sync-entitlement` escriben `entitlements` a partir de este
// resultado, no del tipo de evento recibido: así el estado final no depende
// del orden de llegada de los avisos.
// Copia intencional en sync-entitlement/entitlement_state.ts: cada Edge
// Function se despliega como unidad autocontenida, sin imports cruzados entre
// carpetas de funciones (mismo patrón que entitlement.ts de summarize-article).
// Ver openspec/changes/migrate-to-revenuecat/design.md (D3).
export const ENTITLEMENT_ID = "pro";

const REVENUECAT_API = "https://api.revenuecat.com/v1";

export class RevenueCatApiError extends Error {}

interface SubscriberEntitlement {
  expires_date: string | null;
  grace_period_expires_date?: string | null;
}

export interface SubscriberResponse {
  subscriber?: {
    entitlements?: Record<string, SubscriberEntitlement | undefined>;
  };
}

function isFuture(date: string | null | undefined, now: Date): boolean {
  return date != null && new Date(date).getTime() > now.getTime();
}

/**
 * `GET /v1/subscribers/{id}` devuelve también los entitlements ya vencidos,
 * así que la vigencia se decide por la fecha. `expires_date` nulo es acceso
 * sin vencimiento. Una prueba gratis vigente tiene `expires_date` futuro, por
 * lo que cuenta como activa sin tratarla aparte.
 */
export function isEntitlementActive(
  response: SubscriberResponse,
  now: Date = new Date(),
): boolean {
  const entitlement = response.subscriber?.entitlements?.[ENTITLEMENT_ID];
  if (!entitlement) return false;
  if (entitlement.expires_date == null) return true;
  return isFuture(entitlement.expires_date, now) ||
    isFuture(entitlement.grace_period_expires_date, now);
}

export async function fetchEntitlementActive(opts: {
  appUserId: string;
  secretKey: string;
  fetchFn?: typeof fetch;
  now?: Date;
}): Promise<boolean> {
  const fetchFn = opts.fetchFn ?? fetch;
  let response: Response;
  try {
    response = await fetchFn(
      `${REVENUECAT_API}/subscribers/${encodeURIComponent(opts.appUserId)}`,
      {
        headers: {
          Authorization: `Bearer ${opts.secretKey}`,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (e) {
    throw new RevenueCatApiError(`RevenueCat no responde: ${e}`);
  }
  if (!response.ok) {
    await response.body?.cancel();
    throw new RevenueCatApiError(`RevenueCat respondió ${response.status}`);
  }
  return isEntitlementActive(await response.json(), opts.now);
}
