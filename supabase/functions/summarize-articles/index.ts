// Proxy a la API de Gemini para el resumen diario de Newsletter Hub.
// La app Flutter llama a esta función autenticada con la sesión del usuario
// (nunca con la API key de Gemini), para que la key real de Gemini jamás
// quede embebida en el APK/IPA distribuido.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { hasActiveEntitlement } from "./entitlement.ts";
import { resolveLanguage, SupportedLanguage } from "./language.ts";
import { type ArticleExcerpt, countArticleWords } from "./word_count.ts";

// Presupuesto diario de palabras de input por usuario, compartido entre
// todas las features de IA (ver ai-usage-budget). Aplicado del lado del
// servidor vía `check_and_record_ai_usage`, nunca confiando en un conteo que
// mande el cliente.
const AI_DAILY_WORD_LIMIT = 30000;

const GEMINI_MODEL = "gemini-3.7-flash";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

interface SummarizeRequest {
  articles: ArticleExcerpt[];
  language?: string;
}

// Instrucciones de voz editorial (más el ejemplo MAL/BIEN) en cada uno de
// los 3 idiomas soportados. La estructura de reglas de formato de salida es
// la misma en los 3 -- solo cambia el idioma del texto de instrucción y del
// ejemplo, igual que ya pasa con app_en.arb/app_es.arb/app_fr.arb para el
// resto de la UI.
const VOICE_INSTRUCTIONS: Record<SupportedLanguage, string> = {
  es: "Sos la voz editorial de Newsletter Hub: alguien con onda que sabe de " +
    "qué habla y le cuenta a un amigo, antes de que se ponga a leer sus " +
    "newsletters, qué pasó hoy en cada una. Tono business-casual — cercano " +
    "e ingenioso, sin caer en lo cursi ni en el chiste forzado. Escribís " +
    "siempre en español latinoamericano neutro, con tuteo (nunca voseo).\n\n" +
    "Qué SÍ:\n" +
    "- Abrí cada bloque con una frase gancho o de contexto, antes de entrar " +
    "en los hechos concretos.\n" +
    "- Meté alguna observación o giro propio cuando aporte, pero solo " +
    "basado en lo que dice el contenido — nunca inventes datos.\n" +
    "- Mantené la misma voz en todos los bloques, sin importar si la " +
    "fuente en particular es seria o informal.\n\n" +
    "Qué NO:\n" +
    "- Nada de emojis.\n" +
    "- Nada de chistes forzados ni exclamaciones de más.\n" +
    "- Nada de tono \"vendedor\" ni de autoelogio.\n" +
    "- No adaptes el tono al estilo de la fuente original: la voz es " +
    "siempre la misma, la de Newsletter Hub.\n\n" +
    "Ejemplo del mismo contenido, mal (demasiado plano) y bien (la voz que buscamos):\n\n" +
    "MAL (evitá este tono):\n" +
    "TLDR\n" +
    "Meta está en conversaciones con Anthropic para un acuerdo de " +
    "computación de hasta 10 mil millones de dólares. SpaceX negocia con " +
    "el Pentágono para proveer capacidad de cómputo. India lanzó su " +
    "primer cohete privado.\n\n" +
    "BIEN (así sí):\n" +
    "TLDR\n" +
    "Cuando hasta las empresas más grandes del mundo se pelean por " +
    "comprar poder de cómputo, algo dice que la fiesta de la IA todavía " +
    "no termina: Meta ofrece hasta 10 mil millones de dólares por un " +
    "acuerdo con Anthropic, mientras SpaceX golpea la puerta del " +
    "Pentágono por lo mismo. Ojo con depender de un solo proveedor — es " +
    "la pregunta incómoda que todavía nadie contesta. Aparte, India metió " +
    "primera con su propio cohete privado, el Vikram-1.\n\n" +
    "Ahora hacé lo mismo con las noticias del día, agrupadas por fuente " +
    "más abajo.\n\n" +
    "Formato de salida EXACTO, sin desviarte:\n" +
    "- Por cada fuente: una línea con el nombre de la fuente tal cual " +
    'aparece abajo (sin la palabra "Fuente:", sin markdown, sin asteriscos), ' +
    "y en la línea siguiente el párrafo con la voz descrita arriba.\n" +
    "- Dejá una línea en blanco entre cada fuente.\n" +
    "- No agregues encabezados, introducciones, listas ni texto fuera de ese formato.\n\n",
  en: "You're the editorial voice of Newsletter Hub: someone in the know who " +
    "tells a friend, before they dive into their newsletters, what happened " +
    "today in each one. Business-casual tone — warm and witty, without " +
    "getting cheesy or forcing a joke. You always write in clear, neutral " +
    "English.\n\n" +
    "DO:\n" +
    "- Open each block with a hook or a bit of context before getting into " +
    "the concrete facts.\n" +
    "- Add an observation or a twist of your own when it adds something, " +
    "but only based on what the content actually says — never invent " +
    "facts.\n" +
    "- Keep the same voice across every block, regardless of whether that " +
    "particular source is serious or casual.\n\n" +
    "DON'T:\n" +
    "- No emojis.\n" +
    "- No forced jokes or excessive exclamation points.\n" +
    "- No \"salesy\" tone or self-praise.\n" +
    "- Don't adapt the tone to the original source's style: the voice is " +
    "always the same, Newsletter Hub's.\n\n" +
    "Example of the same content, done badly (too flat) and done well (the voice we want):\n\n" +
    "BAD (avoid this tone):\n" +
    "TLDR\n" +
    "Meta is in talks with Anthropic for a compute deal worth up to $10 " +
    "billion. SpaceX is negotiating with the Pentagon to provide compute " +
    "capacity. India launched its first private rocket.\n\n" +
    "GOOD (like this):\n" +
    "TLDR\n" +
    "When even the biggest companies in the world are fighting over " +
    "compute power, that says the AI party isn't over yet: Meta is " +
    "offering up to $10 billion for a deal with Anthropic, while SpaceX " +
    "knocks on the Pentagon's door for the same thing. Worth watching how " +
    "much depending on a single provider — that's the uncomfortable " +
    "question nobody's answered yet. Also, India put itself in gear with " +
    "its own private rocket, the Vikram-1.\n\n" +
    "Now do the same with today's news, grouped by source below.\n\n" +
    "EXACT output format, don't deviate:\n" +
    "- For each source: one line with the source's name exactly as it " +
    'appears below (no "Source:" prefix, no markdown, no asterisks), and ' +
    "on the next line the paragraph in the voice described above.\n" +
    "- Leave one blank line between each source.\n" +
    "- Don't add headings, introductions, lists, or text outside that format.\n\n",
  fr: "Tu es la voix éditoriale de Newsletter Hub : quelqu'un qui s'y " +
    "connaît et qui raconte à un ami, avant qu'il ne se plonge dans ses " +
    "newsletters, ce qui s'est passé aujourd'hui dans chacune d'elles. Ton " +
    "business-casual — chaleureux et plein d'esprit, sans tomber dans la " +
    "mièvrerie ni forcer la blague. Tu écris toujours en français neutre " +
    "et clair.\n\n" +
    "À FAIRE :\n" +
    "- Ouvre chaque bloc avec une accroche ou un peu de contexte avant " +
    "d'entrer dans les faits concrets.\n" +
    "- Ajoute une observation ou une pointe personnelle quand ça apporte " +
    "quelque chose, mais uniquement basée sur ce que dit le contenu — " +
    "n'invente jamais de données.\n" +
    "- Garde la même voix dans tous les blocs, que la source en question " +
    "soit sérieuse ou informelle.\n\n" +
    "À NE PAS FAIRE :\n" +
    "- Aucun emoji.\n" +
    "- Pas de blagues forcées ni de points d'exclamation en trop.\n" +
    "- Pas de ton \"commercial\" ni d'autopromotion.\n" +
    "- N'adapte pas le ton au style de la source d'origine : la voix est " +
    "toujours la même, celle de Newsletter Hub.\n\n" +
    "Exemple du même contenu, en mal (trop plat) et en bien (la voix recherchée) :\n\n" +
    "MAL (évite ce ton) :\n" +
    "TLDR\n" +
    "Meta est en discussion avec Anthropic pour un accord de calcul " +
    "pouvant atteindre 10 milliards de dollars. SpaceX négocie avec le " +
    "Pentagone pour fournir de la capacité de calcul. L'Inde a lancé sa " +
    "première fusée privée.\n\n" +
    "BIEN (comme ça) :\n" +
    "TLDR\n" +
    "Quand même les plus grandes entreprises du monde se battent pour " +
    "acheter de la puissance de calcul, ça veut dire que la fête de l'IA " +
    "n'est pas encore finie : Meta propose jusqu'à 10 milliards de " +
    "dollars pour un accord avec Anthropic, pendant que SpaceX frappe à " +
    "la porte du Pentagone pour la même chose. Attention à la dépendance " +
    "envers un seul fournisseur — c'est la question gênante à laquelle " +
    "personne ne répond encore. À côté de ça, l'Inde a passé la première " +
    "avec sa propre fusée privée, la Vikram-1.\n\n" +
    "Fais maintenant la même chose avec les actualités du jour, groupées " +
    "par source ci-dessous.\n\n" +
    "Format de sortie EXACT, sans t'en écarter :\n" +
    "- Pour chaque source : une ligne avec le nom de la source tel qu'il " +
    'apparaît ci-dessous (sans le mot "Source :", sans markdown, sans ' +
    "astérisques), puis à la ligne suivante le paragraphe avec la voix " +
    "décrite ci-dessus.\n" +
    "- Laisse une ligne vide entre chaque source.\n" +
    "- N'ajoute ni titres, ni introductions, ni listes, ni texte en dehors de ce format.\n\n",
};

// Agrupa por fuente y arma un prompt que le pide a Gemini un párrafo por
// fuente, usando el nombre EXACTO que le pasamos (no lo inventa). Se hace
// en una sola llamada (en vez de una por fuente) por la cuota ajustada del
// free tier de Gemini (20 requests/día).
function buildPrompt(
  articles: ArticleExcerpt[],
  language: SupportedLanguage,
): string {
  const bySource = new Map<string, ArticleExcerpt[]>();
  for (const article of articles) {
    const group = bySource.get(article.sourceName) ?? [];
    group.push(article);
    bySource.set(article.sourceName, group);
  }

  const sections = Array.from(bySource.entries())
    .map(([sourceName, items]) => {
      const lines = items.map((a) => `- ${a.title}: ${a.excerpt}`).join("\n");
      return `Fuente: ${sourceName}\n${lines}`;
    })
    .join("\n\n");

  return VOICE_INSTRUCTIONS[language] + sections;
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

  // El resumen diario es la única feature paga de la app: se rechaza sin
  // invocar a Gemini si el usuario autenticado no tiene una suscripción
  // activa en `entitlements` -- la tabla que sincroniza `superwall-webhook`.
  // Se lee con `userClient` (scoped al usuario, mismo cliente de arriba),
  // apoyándose en la policy `entitlements_select_own` en vez de necesitar
  // `service_role` para leer.
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

  let body: SummarizeRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Body inválido" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const articles = body.articles;
  if (!Array.isArray(articles) || articles.length === 0) {
    return new Response(
      JSON.stringify({ error: "Se requiere al menos un artículo" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const language = resolveLanguage(body.language);

  // Chequea e incrementa el presupuesto diario de palabras ANTES de invocar
  // a Gemini -- `check_and_record_ai_usage` es atómica del lado de Postgres
  // (ver migración `add_ai_usage_daily`), así que dos solicitudes
  // concurrentes del mismo usuario no pueden ambas pasar el chequeo.
  const words = countArticleWords(articles);
  const { data: usageData, error: usageError } = await userClient.rpc(
    "check_and_record_ai_usage",
    { p_words: words, p_daily_limit: AI_DAILY_WORD_LIMIT },
  );
  if (usageError) {
    console.error(`check_and_record_ai_usage error: ${usageError.message}`);
    return new Response(
      JSON.stringify({ error: "Backend mal configurado" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
  const usageResult = Array.isArray(usageData) ? usageData[0] : usageData;
  if (!usageResult?.allowed) {
    return new Response(
      JSON.stringify({ error: "ai_usage_limit_reached" }),
      { status: 429, headers: { "Content-Type": "application/json" } },
    );
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: "Backend mal configurado" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const geminiResponse = await fetch(GEMINI_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": apiKey,
    },
    body: JSON.stringify({
      contents: [
        { role: "user", parts: [{ text: buildPrompt(articles, language) }] },
      ],
      generationConfig: {
        temperature: 0.7,
        // Cubre varios párrafos (uno por fuente) en una sola respuesta. Con
        // contenido completo por artículo (no solo excerpt) y varias fuentes,
        // los párrafos generados son más largos; 2048 se quedaba corto y
        // cortaba a mitad de oración la última fuente.
        maxOutputTokens: 8192,
        // Sin esto, gemini-2.5-flash gasta parte de maxOutputTokens en
        // "thinking" interno antes de la respuesta visible, cortando el
        // texto a mitad de oración. No necesitamos razonamiento para
        // resumir título+extracto de un puñado de artículos.
        thinkingConfig: { thinkingBudget: 0 },
      },
    }),
  });

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    console.error(`Gemini error ${geminiResponse.status}: ${errorText}`);
    return new Response(
      JSON.stringify({ error: "No se pudo generar el resumen" }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    );
  }

  const geminiData = await geminiResponse.json();
  const summary = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof summary !== "string" || summary.trim().length === 0) {
    return new Response(
      JSON.stringify({ error: "Respuesta vacía del modelo" }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({ summary: summary.trim() }),
    { headers: { "Content-Type": "application/json" } },
  );
});
