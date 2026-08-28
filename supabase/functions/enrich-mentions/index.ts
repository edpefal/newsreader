// Proxy fino a Google Books / iTunes Search para enriquecer menciones a
// libros/podcasts/música con imagen de portada + link (ver capability
// article-mentions). A diferencia de summarize-article, esta función NO
// invoca a Gemini ni descuenta del presupuesto diario de IA -- ver
// design.md de add-article-summary-mentions.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { hasActiveEntitlement } from "./entitlement.ts";
import { isValidRawMention, type RawMention } from "./mention_types.ts";
import { enrichMention } from "./providers.ts";

interface EnrichMentionsRequest {
  mentions: RawMention[];
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Método no permitido" }),
      { status: 405, headers: { "Content-Type": "application/json" } },
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: userData, error: authError } = await userClient.auth.getUser(
    token,
  );
  if (authError || !userData.user) {
    return new Response(
      JSON.stringify({ error: "Token inválido" }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }

  const { data: entitlementRow } = await userClient
    .from("entitlements")
    .select("is_active")
    .eq("user_id", userData.user.id)
    .maybeSingle();
  if (!hasActiveEntitlement(entitlementRow)) {
    return new Response(
      JSON.stringify({ error: "Se requiere una suscripción activa" }),
      { status: 403, headers: { "Content-Type": "application/json" } },
    );
  }

  let body: EnrichMentionsRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Body inválido" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  if (!Array.isArray(body.mentions) || !body.mentions.every(isValidRawMention)) {
    return new Response(
      JSON.stringify({ error: "Se requiere una lista válida de menciones" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  // Cada mención se resuelve de forma independiente (enrichMention nunca
  // rechaza la promesa: una falla puntual de proveedor se traduce en una
  // mención sin imageUrl/link, no en abortar el resto de la request).
  const mentions = await Promise.all(body.mentions.map((m) => enrichMention(m)));

  return new Response(
    JSON.stringify({ mentions }),
    { headers: { "Content-Type": "application/json" } },
  );
});
