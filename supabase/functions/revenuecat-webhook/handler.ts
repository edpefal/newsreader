// Lógica del webhook de RevenueCat, separada de `index.ts` para poder probarla
// con dependencias simuladas. Ante cualquier evento de un usuario consulta a
// RevenueCat el estado vigente del entitlement `pro` y lo refleja en
// `entitlements`; no deduce nada del tipo de evento.
// Ver openspec/changes/migrate-to-revenuecat/design.md (D3).
import { secureEqual } from "./secure_equal.ts";

export interface WebhookDeps {
  /** Valor esperado de la cabecera `Authorization` (REVENUECAT_WEBHOOK_AUTH). */
  authSecret: string;
  /** ¿Existe el usuario en `auth.users` de este proyecto de Supabase? */
  userExists: (userId: string) => Promise<boolean>;
  /** Consulta a RevenueCat si el entitlement `pro` está vigente. */
  fetchEntitlementActive: (appUserId: string) => Promise<boolean>;
  upsertEntitlement: (userId: string, isActive: boolean) => Promise<void>;
}

const ANONYMOUS_PREFIX = "$RCAnonymousID:";
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** Responde 200 para que RevenueCat no reintente un evento que no aplica. */
const ignored = () => json({ received: true });

export async function handleWebhook(
  req: Request,
  deps: WebhookDeps,
): Promise<Response> {
  if (req.method !== "POST") {
    return json({ error: "Método no permitido" }, 405);
  }

  const authorization = req.headers.get("Authorization") ?? "";
  if (!(await secureEqual(authorization, deps.authSecret))) {
    return json({ error: "No autorizado" }, 401);
  }

  let appUserId: string | undefined;
  try {
    const payload = await req.json();
    appUserId = payload?.event?.app_user_id;
  } catch {
    return json({ error: "Body inválido" }, 400);
  }

  // Sin id, con id anónimo de RevenueCat o que no es un uuid de Supabase Auth:
  // no hay a quién actualizarle el entitlement.
  if (
    typeof appUserId !== "string" ||
    appUserId.startsWith(ANONYMOUS_PREFIX) ||
    !UUID_PATTERN.test(appUserId)
  ) {
    return ignored();
  }

  try {
    // Un único proyecto de RevenueCat envía los eventos de `reevo` y de
    // `reevo-dev` a ambos webhooks: quien no existe aquí se ignora, y además
    // `entitlements.user_id` tiene FK a `auth.users`.
    if (!(await deps.userExists(appUserId))) return ignored();

    const isActive = await deps.fetchEntitlementActive(appUserId);
    await deps.upsertEntitlement(appUserId, isActive);
  } catch (e) {
    // 500 para que RevenueCat reintente; `entitlements` queda sin modificar.
    console.error(
      `No se pudo sincronizar el entitlement: ${(e as Error).message}`,
    );
    return json({ error: "No se pudo procesar el evento" }, 500);
  }

  return json({ received: true });
}
