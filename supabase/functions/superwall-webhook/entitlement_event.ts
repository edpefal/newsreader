// Deriva si un evento de Superwall implica otorgar o revocar el acceso.
//
// Verificado contra la documentación vigente
// (superwall.com/docs/integrations/webhooks) al implementar, en vez de
// asumir el detalle exacto descripto en design.md: Superwall NO tiene un
// evento "refund" separado -- un reembolso se señaliza con un valor
// negativo en `price`/`proceeds`/`priceInPurchasedCurrency` sobre alguno
// de los eventos existentes (típicamente `cancellation` o `expiration`),
// así que se chequea explícitamente en vez de buscar un nombre de evento
// que no existe.
//
// `cancellation` ("Subscription cancelled") NO revoca acceso: solo
// significa que el usuario apagó el auto-renew, pero conserva el acceso
// hasta que se cumple el período ya pagado -- ahí es cuando llega
// `expiration` ("Subscription expired"), que sí revoca. Tratar
// `cancellation` como revocación inmediata le cortaría el acceso a alguien
// que todavía no terminó de consumir lo que pagó.
export interface SuperwallWebhookEvent {
  type: string;
  data?: {
    price?: number;
    proceeds?: number;
    priceInPurchasedCurrency?: number;
    originalAppUserId?: string | null;
  };
}

// Eventos que implican que el usuario tiene acceso pago activo.
const GRANT_EVENTS = new Set([
  "initial_purchase",
  "renewal",
  "uncancellation",
  "non_renewing_purchase",
  // El usuario cambió de plan pero sigue con una suscripción activa.
  "product_change",
]);

// Eventos que implican que el usuario ya no tiene acceso pago activo.
// `cancellation` NO está acá a propósito -- ver comentario arriba.
const REVOKE_EVENTS = new Set([
  "expiration",
  "billing_issue",
  "subscription_paused",
]);

function isRefund(event: SuperwallWebhookEvent): boolean {
  const amounts = [
    event.data?.price,
    event.data?.proceeds,
    event.data?.priceInPurchasedCurrency,
  ];
  return amounts.some((amount) => typeof amount === "number" && amount < 0);
}

/**
 * Devuelve `true`/`false` según corresponda otorgar o revocar el acceso, o
 * `null` si el evento no es uno de los reconocidos (se ignora sin tocar
 * `entitlements`, pero se responde 200 igual para que Superwall no
 * reintente indefinidamente).
 */
export function resolveIsActive(
  event: SuperwallWebhookEvent,
): boolean | null {
  if (isRefund(event)) return false;
  if (GRANT_EVENTS.has(event.type)) return true;
  if (REVOKE_EVENTS.has(event.type)) return false;
  return null;
}
