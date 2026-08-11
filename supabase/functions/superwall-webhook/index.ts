// Recibe los eventos de suscripción de Superwall (alta, renovación,
// cancelación, expiración, etc.), valida su firma Svix con
// SUPERWALL_WEBHOOK_SECRET, y mantiene sincronizada `entitlements` -- la
// tabla que `summarize-articles` consulta como fuente de verdad de si un
// usuario puede generar un resumen.
// Ver openspec/changes/gate-daily-summary-behind-superwall-paywall/.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { verifySvixSignature } from "./verify_signature.ts";
import {
  resolveIsActive,
  type SuperwallWebhookEvent,
} from "./entitlement_event.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Método no permitido" }),
      { status: 405, headers: { "Content-Type": "application/json" } },
    );
  }

  const secret = Deno.env.get("SUPERWALL_WEBHOOK_SECRET");
  if (!secret) {
    console.error("SUPERWALL_WEBHOOK_SECRET no configurado");
    return new Response(
      JSON.stringify({ error: "Backend mal configurado" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  // La firma se calcula sobre el body crudo -- nunca parsear JSON antes de
  // verificar, invalida la firma.
  const rawBody = await req.text();
  const isValid = await verifySvixSignature({
    secret,
    svixId: req.headers.get("svix-id"),
    svixTimestamp: req.headers.get("svix-timestamp"),
    rawBody,
    svixSignatureHeader: req.headers.get("svix-signature"),
  });
  if (!isValid) {
    return new Response(
      JSON.stringify({ error: "Firma inválida" }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }

  let event: SuperwallWebhookEvent;
  try {
    event = JSON.parse(rawBody);
  } catch {
    return new Response(
      JSON.stringify({ error: "Body inválido" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  // Requiere SDK de Superwall v4.5.2+ para venir poblado. Sin esto no hay
  // a quién actualizarle el entitlement -- se reconoce el evento (200)
  // para que Superwall no lo reintente, pero no se toca `entitlements`.
  const userId = event.data?.originalAppUserId;
  const isActive = userId ? resolveIsActive(event) : null;
  if (!userId || isActive === null) {
    return new Response(
      JSON.stringify({ received: true }),
      { headers: { "Content-Type": "application/json" } },
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin = createClient(supabaseUrl, serviceRoleKey);

  const { error } = await admin.from("entitlements").upsert({
    user_id: userId,
    is_active: isActive,
    updated_at: new Date().toISOString(),
  });

  if (error) {
    console.error(`No se pudo actualizar entitlements: ${error.message}`);
    return new Response(
      JSON.stringify({ error: "No se pudo procesar el evento" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({ received: true }),
    { headers: { "Content-Type": "application/json" } },
  );
});
