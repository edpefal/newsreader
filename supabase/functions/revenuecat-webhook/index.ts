// Recibe los avisos de suscripción de RevenueCat y mantiene sincronizada
// `entitlements` -- la tabla que `summarize-article` y
// `generate-daily-summaries` consultan como fuente de verdad de si un usuario
// tiene suscripción activa. Autentica el request con el valor de la cabecera
// `Authorization` (REVENUECAT_WEBHOOK_AUTH) y consulta el estado a la API REST
// (REVENUECAT_SECRET_API_KEY) en vez de interpretar el tipo de evento.
// Ver openspec/changes/migrate-to-revenuecat/.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { fetchEntitlementActive } from "./entitlement_state.ts";
import { handleWebhook } from "./handler.ts";

Deno.serve((req) => {
  const authSecret = Deno.env.get("REVENUECAT_WEBHOOK_AUTH");
  const secretKey = Deno.env.get("REVENUECAT_SECRET_API_KEY");
  if (!authSecret || !secretKey) {
    console.error(
      "REVENUECAT_WEBHOOK_AUTH o REVENUECAT_SECRET_API_KEY no configurado",
    );
    return Promise.resolve(
      new Response(JSON.stringify({ error: "Backend mal configurado" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }),
    );
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  return handleWebhook(req, {
    authSecret,
    userExists: async (userId) => {
      const { data, error } = await admin.auth.admin.getUserById(userId);
      if (error) {
        if (error.status === 404) return false;
        throw new Error(`No se pudo consultar el usuario: ${error.message}`);
      }
      return data.user != null;
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
