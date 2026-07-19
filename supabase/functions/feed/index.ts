// Sirve el feed RSS 2.0 de un feed generado, armado on-demand a partir de
// los feed_items guardados. Ver openspec/changes/email-to-rss-generated-feeds/design.md.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

function escapeXml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

interface FeedItemRow {
  id: string;
  title: string;
  content_html: string;
  received_at: string;
}

function buildRss(
  feedId: string,
  feedUrl: string,
  label: string | null,
  items: FeedItemRow[],
): string {
  const channelTitle = escapeXml(label ?? "Newsletter sin nombre");
  const itemsXml = items.map((item) => {
    const pubDate = new Date(item.received_at).toUTCString();
    // <link> debe ser único por item: SyncSources (lib/features/inbox/domain/
    // usecases/sync_sources.dart) deduplica por item.link, no por guid. Si
    // todos los items compartieran el <link> del feed, solo el primer email
    // se sincronizaría — los siguientes se descartarían como "duplicados".
    const itemLink = `${feedUrl}#${item.id}`;
    // El contenido completo va en <content:encoded>, no en <description>:
    // el FeedParser del cliente (WebfeedFeedParser) mapea contentHtml desde
    // content:encoded y excerpt desde description. Sin content:encoded, la
    // app trataría cada email como "contenido truncado" sin poder mostrarlo
    // completo (no hay una URL de artículo real para abrir en WebView).
    return `    <item>
      <title>${escapeXml(item.title)}</title>
      <link>${escapeXml(itemLink)}</link>
      <guid isPermaLink="false">${escapeXml(item.id)}</guid>
      <pubDate>${pubDate}</pubDate>
      <content:encoded><![CDATA[${item.content_html}]]></content:encoded>
    </item>`;
  }).join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>${channelTitle}</title>
    <link>${escapeXml(feedUrl)}</link>
    <description>Feed generado a partir de correos enviados a ${
    escapeXml(feedId)
  }</description>
${itemsXml}
  </channel>
</rss>
`;
}

Deno.serve(async (req) => {
  if (req.method !== "GET") {
    return new Response("Método no permitido", { status: 405 });
  }

  const url = new URL(req.url);
  const feedId = url.pathname.split("/").filter(Boolean).pop();

  if (!feedId) {
    return new Response("Falta el id del feed", { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: feed, error: feedError } = await supabase
    .from("generated_feeds")
    .select("id, label")
    .eq("id", feedId)
    .maybeSingle();

  if (feedError) {
    console.error(`Error buscando feed ${feedId}: ${feedError.message}`);
    return new Response("Error interno", { status: 500 });
  }

  if (!feed) {
    return new Response("El feed no existe", { status: 404 });
  }

  const { data: items, error: itemsError } = await supabase
    .from("feed_items")
    .select("id, title, content_html, received_at")
    .eq("feed_id", feedId)
    .order("received_at", { ascending: false });

  if (itemsError) {
    console.error(`Error obteniendo items de ${feedId}: ${itemsError.message}`);
    return new Response("Error interno", { status: 500 });
  }

  const feedUrl = `${Deno.env.get("SUPABASE_URL")}/functions/v1/feed/${feedId}`;
  const xml = buildRss(feedId, feedUrl, feed.label, items ?? []);

  return new Response(xml, {
    headers: { "Content-Type": "application/rss+xml; charset=utf-8" },
  });
});
