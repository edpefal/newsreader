// Elimina irreversiblemente la cuenta del usuario autenticado y todos sus
// datos asociados. Se apoya en `on delete cascade` de las FKs de `sources`,
// `articles` y `daily_summaries` hacia `auth.users` (ver
// 20260725000000_sync_user_data.sql): basta con borrar el usuario de
// `auth.users` vía `service_role` para que Postgres cascadee el resto, sin
// necesidad de borrar filas explícitamente acá.
// Ver openspec/changes/add-account-deletion-and-data-export/design.md.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { deleteRevenueCatCustomer } from "./revenuecat.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método no permitido" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data, error: authError } = await userClient.auth.getUser(token);
  if (authError || !data.user) {
    return new Response(JSON.stringify({ error: "Token inválido" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }
  const userId = data.user.id;

  // Antes de borrar `auth.users`, mientras el user_id aún existe. Un fallo no
  // bloquea el borrado de la cuenta (ver revenuecat.ts).
  await deleteRevenueCatCustomer({
    appUserId: userId,
    secretKey: Deno.env.get("REVENUECAT_SECRET_API_KEY"),
  });

  const admin = createClient(supabaseUrl, serviceRoleKey);
  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    console.error(`Error eliminando cuenta ${userId}: ${deleteError.message}`);
    return new Response(JSON.stringify({ error: "Error interno" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
