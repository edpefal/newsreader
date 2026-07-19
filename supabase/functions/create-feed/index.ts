// Genera una dirección de email única y su feed RSS correspondiente
// (kill-the-newsletter-style). Ver openspec/changes/email-to-rss-generated-feeds/design.md.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Límite básico anti-abuso: como esta función se llama con el anon key
// público (mismo modelo que summarize-articles), cualquiera que lo extraiga
// del APK podría generar feeds sin límite. Un tope simple por hora alcanza
// para una app de uso personal sin sistema de cuentas.
const MAX_FEEDS_PER_HOUR = 20;

interface CreateFeedRequest {
  label?: string;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Método no permitido" }),
      { status: 405, headers: { "Content-Type": "application/json" } },
    );
  }

  const emailDomain = Deno.env.get("EMAIL_DOMAIN");
  if (!emailDomain) {
    return new Response(
      JSON.stringify({ error: "Backend mal configurado" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  let body: CreateFeedRequest;
  try {
    body = await req.json();
  } catch {
    body = {};
  }

  const label = typeof body.label === "string" && body.label.trim().length > 0
    ? body.label.trim()
    : null;

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const { count, error: countError } = await supabase
    .from("generated_feeds")
    .select("id", { count: "exact", head: true })
    .gte("created_at", oneHourAgo);

  if (countError) {
    console.error(`Error contando feeds recientes: ${countError.message}`);
    return new Response(
      JSON.stringify({ error: "No se pudo generar el feed" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  if ((count ?? 0) >= MAX_FEEDS_PER_HOUR) {
    return new Response(
      JSON.stringify({ error: "Límite de feeds generados alcanzado, intentá más tarde" }),
      { status: 429, headers: { "Content-Type": "application/json" } },
    );
  }

  const { data, error } = await supabase
    .from("generated_feeds")
    .insert({ label })
    .select("id")
    .single();

  if (error || !data) {
    console.error(`Error creando feed: ${error?.message}`);
    return new Response(
      JSON.stringify({ error: "No se pudo generar el feed" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const id = data.id as string;
  const email = `${id}@${emailDomain}`;
  const feedUrl = `${Deno.env.get("SUPABASE_URL")}/functions/v1/feed/${id}`;

  return new Response(
    JSON.stringify({ id, email, feedUrl }),
    { headers: { "Content-Type": "application/json" } },
  );
});
