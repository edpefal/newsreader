// Recibe el webhook de email entrante y lo convierte en un item de feed.
// Agnóstico del proveedor de email entrante (ver providers/email_provider.ts)
// para poder reemplazar ForwardEmail.net en el futuro (otro proveedor, o un
// servidor SMTP propio) sin tocar esta lógica de negocio.
// Ver openspec/changes/email-to-rss-generated-feeds/design.md.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import type { EmailProvider } from "./providers/email_provider.ts";
import { ForwardEmailProvider } from "./providers/forward_email_provider.ts";

const provider: EmailProvider = new ForwardEmailProvider();

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Método no permitido", { status: 405 });
  }

  if (!(await provider.verifyRequest(req))) {
    return new Response("No autorizado", { status: 401 });
  }

  let json: unknown;
  try {
    json = await req.json();
  } catch {
    return new Response("Body inválido", { status: 400 });
  }

  const email = provider.parsePayload(json);
  const feedId = email.toAddress.split("@")[0];
  if (!feedId) {
    return new Response("Dirección de destino inválida", { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: feed, error: feedError } = await supabase
    .from("generated_feeds")
    .select("id")
    .eq("id", feedId)
    .maybeSingle();

  if (feedError) {
    console.error(`Error buscando feed ${feedId}: ${feedError.message}`);
    return new Response("Error interno", { status: 500 });
  }

  if (!feed) {
    return new Response("El feed no existe", { status: 404 });
  }

  const { error: insertError } = await supabase.from("feed_items").insert({
    feed_id: feedId,
    title: email.subject,
    content_html: email.contentHtml,
    from_address: email.fromAddress,
    received_at: email.receivedAt.toISOString(),
    message_id: email.messageId,
  });

  // Código 23505 = violación de unique constraint (feed_id, message_id):
  // reintento de entrega del mismo correo, no es un error real.
  if (insertError && insertError.code !== "23505") {
    console.error(`Error guardando item: ${insertError.message}`);
    return new Response("Error interno", { status: 500 });
  }

  return new Response("OK", { status: 200 });
});
