// Sincroniza `entitlements` con RevenueCat para el usuario autenticado.
// `verify_jwt = true` en config.toml; el `user_id` sale del token, nunca del
// body. Ver openspec/changes/migrate-to-revenuecat/.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { fetchEntitlementActive } from "./entitlement_state.ts";
import { handleSync } from "./handler.ts";

Deno.serve((req) => {
  const secretKey = Deno.env.get("REVENUECAT_SECRET_API_KEY");
  if (!secretKey) {
    console.error("REVENUECAT_SECRET_API_KEY no configurado");
    return Promise.resolve(
      new Response(JSON.stringify({ error: "Backend mal configurado" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }),
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const admin = createClient(
    supabaseUrl,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  return handleSync(req, {
    authenticate: async (token) => {
      const userClient = createClient(
        supabaseUrl,
        Deno.env.get("SUPABASE_ANON_KEY")!,
        { global: { headers: { Authorization: `Bearer ${token}` } } },
      );
      const { data, error } = await userClient.auth.getUser(token);
      return error || !data.user ? null : data.user.id;
    },
    fetchEntitlementActive: (appUserId) =>
      fetchEntitlementActive({ appUserId, secretKey }),
    upsertEntitlement: async (userId, isActive) => {
      const { error } = await admin.from("entitlements").upsert({
        user_id: userId,
        is_active: isActive,
        updated_at: new Date().toISOString(),
      });
      if (error) {
        throw new Error(`No se pudo actualizar entitlements: ${error.message}`);
      }
    },
  });
});
