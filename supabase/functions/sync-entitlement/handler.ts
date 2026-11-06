// Sincroniza `entitlements` con el estado vigente de RevenueCat para el usuario
// de la sesión. El cliente lo invoca tras una compra o restauración, antes de
// la acción que dependía de la suscripción, para que `summarize-article` no
// responda 403 mientras el webhook aún no llega.
// Opera solo sobre el usuario del token: ignora cualquier `user_id` del body.
// Ver openspec/changes/migrate-to-revenuecat/design.md (D4).

export interface SyncDeps {
  /** `user_id` dueño del access token, o `null` si el token no es válido. */
  authenticate: (token: string) => Promise<string | null>;
  /** Consulta a RevenueCat si el entitlement `pro` está vigente. */
  fetchEntitlementActive: (appUserId: string) => Promise<boolean>;
  upsertEntitlement: (userId: string, isActive: boolean) => Promise<void>;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export async function handleSync(
  req: Request,
  deps: SyncDeps,
): Promise<Response> {
  if (req.method !== "POST") {
    return json({ error: "Método no permitido" }, 405);
  }

  const token = (req.headers.get("Authorization") ?? "").replace(
    /^Bearer\s+/i,
    "",
  );
  const userId = token ? await deps.authenticate(token) : null;
  if (!userId) return json({ error: "Token inválido" }, 401);

  try {
    const isActive = await deps.fetchEntitlementActive(userId);
    await deps.upsertEntitlement(userId, isActive);
    return json({ is_active: isActive });
  } catch (e) {
    console.error(
      `No se pudo sincronizar el entitlement: ${(e as Error).message}`,
    );
    return json({ error: "No se pudo sincronizar" }, 500);
  }
}
