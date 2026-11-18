// Lógica del webhook de RevenueCat, separada de `index.ts` para poder probarla
// con dependencias simuladas. Ante cualquier evento consulta a RevenueCat el
// estado vigente del entitlement `pro` de cada usuario involucrado (uno en un
// evento normal; origen y destino en un traspaso) y lo refleja en
// `entitlements`; no deduce nada del tipo de evento.
// Ver openspec/changes/migrate-to-revenuecat/design.md (D3) y
// openspec/changes/handle-revenuecat-transfer-events/design.md.
import { resolveEventUsers } from "./event_users.ts";
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

  let event: unknown;
  try {
    event = (await req.json())?.event;
  } catch {
    return json({ error: "Body inválido" }, 400);
  }

  // Sin usuarios identificables (p. ej. un evento de prueba sin `app_user_id`
  // ni listas de traspaso): no hay a quién actualizarle el entitlement.
  const { userIds, truncated } = resolveEventUsers(event);
  if (truncated) {
    console.warn(
      "Evento con más usuarios que el tope: se ignoran los sobrantes",
    );
  }

  // Se intenta con todos aunque alguno falle, para no dejar sin sincronizar a
  // quien sí se podía. Si hubo algún fallo se responde 500 y RevenueCat
  // reintenta el evento completo; es seguro porque cada escritura refleja el
  // estado vigente, no el contenido del evento.
  let failures = 0;
  for (const userId of userIds) {
    try {
      await syncUser(userId, deps);
    } catch (e) {
      failures++;
      console.error(
        `No se pudo sincronizar el entitlement: ${(e as Error).message}`,
      );
    }
  }
  if (failures > 0) {
    return json({ error: "No se pudo procesar el evento" }, 500);
  }

  return json({ received: true });
}

/** Sincroniza `entitlements` de un usuario; omite los que no aplican. */
async function syncUser(userId: string, deps: WebhookDeps): Promise<void> {
  // Id anónimo de RevenueCat o que no es un uuid de Supabase Auth: no hay a
  // quién actualizarle el entitlement.
  if (userId.startsWith(ANONYMOUS_PREFIX) || !UUID_PATTERN.test(userId)) return;

  // Un único proyecto de RevenueCat envía los eventos de `reevo` y de
  // `reevo-dev` a ambos webhooks: quien no existe aquí se ignora, y además
  // `entitlements.user_id` tiene FK a `auth.users`.
  if (!(await deps.userExists(userId))) return;

  const isActive = await deps.fetchEntitlementActive(userId);
  await deps.upsertEntitlement(userId, isActive);
}
