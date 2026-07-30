// Fetch centralizado de feeds RSS/Atom del lado del servidor. Reemplaza a
// SyncSources (client-side, eliminado en este change) como único creador de
// artículos: dos dispositivos de la misma cuenta nunca vuelven a generar el
// mismo artículo con ids distintos, porque ningún cliente crea artículos.
// Se invoca únicamente on-demand (pull-to-refresh del cliente, autenticado
// con el JWT del usuario) -- sin cron baseline, ver decisión en design.md.
// Ver openspec/changes/centralize-feed-fetching/design.md.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import Parser from "npm:rss-parser@^3";

const FEED_FETCH_TIMEOUT_MS = 10_000;
// Fetch + parseo sin límite de concurrencia (Promise.all de todas las
// fuentes a la vez) agota los recursos del Edge Function cuando hay
// muchas fuentes en una sola invocación. Se procesa en lotes acotados en
// su lugar. CONCURRENCY=1 (totalmente secuencial) resultó demasiado lento
// en la práctica -- con una sola fuente colgada, ya suma los 10s completos
// del timeout antes de seguir con las demás. CONCURRENCY=3 + el tope de 20
// fuentes por invocación se probó estable en despliegue (sin
// WORKER_RESOURCE_LIMIT) y baja bastante el tiempo total.
const CONCURRENCY = 3;
const MAX_SOURCES_PER_INVOCATION = 20;

interface SourceRow {
  id: string;
  user_id: string;
  feed_url: string;
  name: string;
  icon_url: string | null;
  author: string | null;
}

// content:encoded no es un campo estándar de rss-parser -- hay que pedirlo
// explícitamente como custom field, igual que el cliente (WebfeedFeedParser)
// lee item.content?.value desde ese mismo tag para el HTML completo.
const parser = new Parser({
  customFields: { item: [["content:encoded", "contentEncoded"]] },
});

async function mapWithConcurrency<T, R>(
  items: T[],
  limit: number,
  fn: (item: T) => Promise<R>,
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let next = 0;
  async function worker() {
    while (next < items.length) {
      const i = next++;
      results[i] = await fn(items[i]);
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return results;
}

async function fetchWithTimeout(url: string, ms: number): Promise<string> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), ms);
  try {
    const res = await fetch(url, { signal: controller.signal });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.text();
  } finally {
    clearTimeout(timeout);
  }
}

async function syncSource(
  admin: SupabaseClient,
  source: SourceRow,
): Promise<{ ok: boolean; sourceId: string }> {
  try {
    const xml = await fetchWithTimeout(source.feed_url, FEED_FETCH_TIMEOUT_MS);
    // deno-lint-ignore no-explicit-any
    const feed = await parser.parseString(xml) as any;

    const rows = (feed.items ?? [])
      .filter((item: any) => !!item.link)
      .map((item: any) => ({
        user_id: source.user_id,
        source_id: source.id,
        source_name: source.name,
        source_icon_url: source.icon_url,
        title: (item.title?.trim()) || "Sin título",
        author: item.creator ?? item.author ?? source.author ?? null,
        published_at: item.isoDate ?? new Date().toISOString(),
        content_html: item.contentEncoded ?? item.content ?? null,
        excerpt: item.contentSnippet ?? item.summary ?? null,
        article_url: item.link,
      }));

    if (rows.length > 0) {
      const { error } = await admin
        .from("articles")
        .upsert(rows, { onConflict: "source_id,article_url", ignoreDuplicates: true });
      if (error) throw error;
    }

    await admin
      .from("sources")
      .update({ last_synced_at: new Date().toISOString(), has_error: false })
      .eq("id", source.id);

    return { ok: true, sourceId: source.id };
  } catch (e) {
    console.error(`Error sincronizando fuente ${source.id} (${source.feed_url}): ${e}`);
    await admin.from("sources").update({ has_error: true }).eq("id", source.id);
    return { ok: false, sourceId: source.id };
  }
}

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

  const admin = createClient(supabaseUrl, serviceRoleKey);

  // Sin cron: la única forma de invocar esta función es on-demand, con el
  // JWT del usuario (pull-to-refresh). Se valida el token y se procesan
  // solo las fuentes de ese usuario.
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data, error } = await userClient.auth.getUser(token);
  if (error || !data.user) {
    return new Response(JSON.stringify({ error: "Token inválido" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }
  const userId = data.user.id;

  // Tope duro de fuentes por invocación: procesar demasiadas en una sola
  // invocación agota el presupuesto de cómputo del Edge Function
  // (confirmado en despliegue: WORKER_RESOURCE_LIMIT ya con ~45 fuentes de
  // un solo usuario). Se prioriza lo menos sincronizado recientemente, así
  // que un usuario con más fuentes que el tope se termina de poner al día
  // en pull-to-refresh sucesivos en vez de fallar.
  const { data: sources, error: sourcesError } = await admin
    .from("sources")
    .select("id, user_id, feed_url, name, icon_url, author")
    .eq("user_id", userId)
    .is("deleted_at", null)
    .order("last_synced_at", { ascending: true, nullsFirst: true })
    .limit(MAX_SOURCES_PER_INVOCATION);
  if (sourcesError) {
    console.error(`Error obteniendo fuentes: ${sourcesError.message}`);
    return new Response(JSON.stringify({ error: "Error interno" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const results = await mapWithConcurrency(
    (sources ?? []) as SourceRow[],
    CONCURRENCY,
    (source) => syncSource(admin, source),
  );

  const failedSourceIds = results.filter((r) => !r.ok).map((r) => r.sourceId);
  const synced = results.length - failedSourceIds.length;

  return new Response(
    JSON.stringify({ synced, total: results.length, failedSourceIds }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
