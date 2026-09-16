// Genera automáticamente el resumen diario de cada usuario elegible, sin
// que abra la app -- ver
// openspec/changes/add-automatic-daily-summary/design.md, Decisión 3.
// Invocada por un cron (pg_cron + pg_net) cada hora con `service_role`; no
// tiene caller de cliente ni de usuario, a diferencia del extinto
// `summarize-articles` (endpoint HTTP invocado por la app, eliminado en
// este mismo change -- su lógica de prompt se reutiliza acá, ver `prompt.ts`).
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { articleContentFor } from "./content_selection.ts";
import { hasActiveEntitlement, type EntitlementRow } from "./entitlement.ts";
import { isEligibleToday, isMondayLocal, isPastGenerationThreshold } from "./eligibility.ts";
import { resolveLanguage, type SupportedLanguage } from "./language.ts";
import { localDayRange } from "./local_day_range.ts";
import { buildPrompt } from "./prompt.ts";
import { buildSourceBlocks } from "./source_blocks.ts";
import { hasSummaryForToday, resolveUtcOffsetMinutes } from "./user_context.ts";

const GEMINI_MODEL = "gemini-3.7-flash";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

// "Razonablemente temprano en la mañana local" (ver design.md, Decisión 3)
// -- no se garantiza al minuto, el cron corre cada hora.
const GENERATION_THRESHOLD_HOUR = 6;

interface UserPreferenceRow {
  user_id: string;
  locale: string | null;
  utc_offset_minutes: number | null;
}

interface ArticleRow {
  id: string;
  source_id: string;
  source_name: string;
  title: string;
  content_html: string | null;
  excerpt: string | null;
}

type GenerationOutcome =
  | "generated"
  | "already_generated"
  | "no_articles_today"
  | "existing_summary_check_failed"
  | "articles_fetch_failed"
  | "missing_api_key"
  | "gemini_error"
  | "empty_summary"
  | "insert_failed";

async function generateForUser(
  admin: SupabaseClient,
  userId: string,
  utcOffsetMinutes: number,
  locale: SupportedLanguage,
  now: Date,
): Promise<GenerationOutcome> {
  const { start, end } = localDayRange(now, utcOffsetMinutes);

  // Idempotencia: si ya existe un `DailySummary` para hoy (local) de este
  // usuario, no se invoca a Gemini ni se sobreescribe nada (ver requirement
  // "Un único resumen por día, sin regeneración").
  const { data: existingSummary, error: existingError } = await admin
    .from("daily_summaries")
    .select("id")
    .eq("user_id", userId)
    .gte("date", start.toISOString())
    .lt("date", end.toISOString())
    .maybeSingle();
  if (existingError) {
    console.error(
      `chequeo de resumen existente falló (${userId}): ${existingError.message}`,
    );
    return "existing_summary_check_failed";
  }
  if (hasSummaryForToday(existingSummary)) {
    return "already_generated";
  }

  const { data: articleRows, error: articlesError } = await admin
    .from("articles")
    .select("id, source_id, source_name, title, content_html, excerpt")
    .eq("user_id", userId)
    .is("deleted_at", null)
    .eq("is_read", false)
    .eq("is_archived", false)
    .gte("published_at", start.toISOString())
    .lt("published_at", end.toISOString());
  if (articlesError) {
    console.error(
      `fetch de artículos falló (${userId}): ${articlesError.message}`,
    );
    return "articles_fetch_failed";
  }
  if (!articleRows || articleRows.length === 0) {
    return "no_articles_today";
  }
  const articles = articleRows as ArticleRow[];

  const excerpts = articles.map((a) => ({
    title: a.title,
    excerpt: articleContentFor(a),
    sourceName: a.source_name,
  }));

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    console.error("GEMINI_API_KEY no configurada");
    return "missing_api_key";
  }

  const geminiResponse = await fetch(GEMINI_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": apiKey,
    },
    body: JSON.stringify({
      contents: [
        { role: "user", parts: [{ text: buildPrompt(excerpts, locale) }] },
      ],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 8192,
        thinkingConfig: { thinkingBudget: 0 },
      },
    }),
  });
  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    console.error(`Gemini error ${geminiResponse.status} (${userId}): ${errorText}`);
    return "gemini_error";
  }

  const geminiData = await geminiResponse.json();
  const summaryText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof summaryText !== "string" || summaryText.trim().length === 0) {
    console.error(`Respuesta vacía de Gemini (${userId})`);
    return "empty_summary";
  }

  const sourceBlocks = buildSourceBlocks(articles);
  const nowIso = now.toISOString();
  // El PK de `daily_summaries` es global (`id text primary key`), no
  // compuesto con `user_id`: a diferencia del cliente (que genera
  // `dateKey(date)` porque cada dispositivo solo ve su propio usuario), acá
  // hay que prefijar con el `userId` para no colisionar con el resumen de
  // otro usuario en la misma fecha local.
  const id = `${userId}-${start.toISOString().slice(0, 10)}`;

  const { error: insertError } = await admin.from("daily_summaries").insert({
    id,
    user_id: userId,
    date: start.toISOString(),
    content: summaryText.trim(),
    article_count: articles.length,
    created_at: nowIso,
    updated_at: nowIso,
    source_blocks: sourceBlocks,
  });
  if (insertError) {
    console.error(`No se pudo persistir el resumen (${userId}): ${insertError.message}`);
    return "insert_failed";
  }

  return "generated";
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método no permitido" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  // Invocable únicamente por el cron del servidor (`service_role`): no hay
  // caller humano ni de cliente para esta función.
  if (token !== serviceRoleKey) {
    return new Response(JSON.stringify({ error: "No autorizado" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const admin = createClient(supabaseUrl, serviceRoleKey);

  // Usuarios con al menos una fuente (ver requirement "Disparo automático
  // de la generación"). Sin `distinct` del lado de Postgrest: se dedupea
  // en memoria.
  const { data: sourceRows, error: sourcesError } = await admin
    .from("sources")
    .select("user_id")
    .is("deleted_at", null);
  if (sourcesError) {
    console.error(`Error obteniendo usuarios con fuentes: ${sourcesError.message}`);
    return new Response(JSON.stringify({ error: "Error interno" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
  const userIds = Array.from(
    new Set((sourceRows ?? []).map((r) => r.user_id as string)),
  );
  if (userIds.length === 0) {
    return new Response(JSON.stringify({ evaluated: 0, generated: 0 }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  const { data: prefRows } = await admin
    .from("user_preferences")
    .select("user_id, locale, utc_offset_minutes")
    .in("user_id", userIds);
  const prefsByUser = new Map(
    ((prefRows ?? []) as UserPreferenceRow[]).map((r) => [r.user_id, r]),
  );

  const { data: entitlementRows } = await admin
    .from("entitlements")
    .select("user_id, is_active")
    .in("user_id", userIds);
  const entitlementsByUser = new Map(
    ((entitlementRows ?? []) as (EntitlementRow & { user_id: string })[]).map(
      (r) => [r.user_id, r],
    ),
  );

  const now = new Date();
  let evaluated = 0;
  let generated = 0;

  for (const userId of userIds) {
    const pref = prefsByUser.get(userId) ?? null;
    // Sin preferencia sincronizada todavía: default UTC+0 e inglés (ver
    // capability `user-preferences`, requirement "Valor por defecto antes
    // de la primera sincronización").
    const utcOffsetMinutes = resolveUtcOffsetMinutes(pref);
    const locale = resolveLanguage(pref?.locale);

    if (!isPastGenerationThreshold(now, utcOffsetMinutes, GENERATION_THRESHOLD_HOUR)) {
      continue;
    }

    const isSubscribed = hasActiveEntitlement(
      entitlementsByUser.get(userId) ?? null,
    );
    const eligible = isEligibleToday(
      isSubscribed,
      isMondayLocal(now, utcOffsetMinutes),
    );
    if (!eligible) continue;

    evaluated++;
    const outcome = await generateForUser(
      admin,
      userId,
      utcOffsetMinutes,
      locale,
      now,
    );
    if (outcome === "generated") generated++;
  }

  return new Response(JSON.stringify({ evaluated, generated }), {
    headers: { "Content-Type": "application/json" },
  });
});
