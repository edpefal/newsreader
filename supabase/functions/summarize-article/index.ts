// Proxy a la API de Gemini para el resumen de un artículo individual +
// detección de menciones a libros/podcasts/música (ver capabilities
// article-summaries y article-mentions). Mismo patrón de auth y cuota que
// summarize-articles: la app nunca ve la key real de Gemini, se autentica
// con el access token de la sesión activa, y descuenta del mismo
// presupuesto diario de palabras compartido entre features de IA.
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { hasActiveEntitlement } from "./entitlement.ts";
import { resolveLanguage, SupportedLanguage } from "./language.ts";
import { countSingleArticleWords } from "./word_count.ts";
import { MENTION_TYPES, parseMentions } from "./mentions.ts";

const AI_DAILY_WORD_LIMIT = 30000;

const GEMINI_MODEL = "gemini-3.7-flash";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

interface SummarizeArticleRequest {
  title: string;
  content: string;
  language?: string;
}

// Instrucciones de voz + extracción de menciones en los 3 idiomas
// soportados. A diferencia de summarize-articles (agrupado por fuente),
// acá el resumen es de un solo artículo, y se le pide a Gemini que además
// devuelva las menciones a libros/podcasts/música en el mismo JSON -- ver
// design.md de add-article-summary-mentions.
const INSTRUCTIONS: Record<SupportedLanguage, string> = {
  es: "Eres la voz editorial de Newsletter Hub: alguien con onda que sabe de " +
    "qué habla y le resume a un amigo, en un párrafo, de qué trata este " +
    "artículo. Tono business-casual — cercano e ingenioso, sin caer en lo " +
    "cursi ni en el chiste forzado, sin emojis. Escribe siempre en " +
    "español latinoamericano neutro, con tuteo (nunca voseo). Basa el " +
    "resumen solo en lo que dice el artículo, nunca inventes datos.\n\n" +
    "Qué NO: no hagas un resumen tipo Wikipedia que enumera de forma plana " +
    "los temas que toca el artículo. Agrega una frase gancho o un ángulo " +
    "propio (basado solo en lo que dice el artículo), como si se lo " +
    "estuvieras contando a un amigo antes de que lo lea.\n\n" +
    "Ejemplo del mismo artículo, mal (demasiado plano) y bien (la voz que " +
    "buscamos):\n\n" +
    "MAL (evita este tono):\n" +
    "El artículo explica un marco de seis preguntas para navegar " +
    "transiciones de carrera, basado en más de 1000 entrevistas y sesiones " +
    "de coaching. Distingue entre progreso y progresión de carrera, e " +
    "identifica cuatro motivaciones para cambiar de trabajo: salir de una " +
    "situación insostenible, recuperar el control, recuperar la alineación, " +
    "y dar el siguiente paso.\n\n" +
    "BIEN (así sí):\n" +
    "Si sientes que necesitas un cambio de trabajo pero no sabes bien hacia " +
    "dónde, este artículo te da un mapa: a partir de más de 1000 " +
    "entrevistas y cientos de sesiones de coaching, el autor arma cuatro " +
    "motivos típicos detrás de un cambio de carrera -- desde escapar de un " +
    "jefe imposible hasta simplemente querer dar el próximo salto. La idea " +
    "central: dejar de perseguir \"progresión\" (subir la escalera) y " +
    "empezar a buscar \"progreso\" (lo que de verdad necesitas en este " +
    "momento de tu vida, sea autonomía, estabilidad o reconocimiento).\n\n" +
    "Ahora haz lo mismo con el artículo de abajo.\n\n" +
    "Además, identifica cualquier libro, podcast o álbum/canción que el " +
    "artículo mencione explícitamente. El artículo de abajo puede contener " +
    "links en formato [texto del link](url) -- identifica cuáles de esos " +
    "links corresponden a otro artículo que el autor menciona o cita " +
    "explícitamente (no links de navegación, redes sociales, \"suscribite\" " +
    "u otras llamadas a la acción) y devuélvelos como una mención de tipo " +
    "\"article\", con la URL exacta del link. Si no hay ninguna mención de " +
    "ningún tipo, devuelve una lista vacía -- no inventes menciones que no " +
    "estén en el texto.\n\n" +
    "Artículo:\n",
  en: "You're the editorial voice of Newsletter Hub: someone in the know " +
    "who sums up, in one paragraph, what this article is about for a " +
    "friend. Business-casual tone — warm and witty, without getting cheesy " +
    "or forcing a joke, no emojis. Always write in clear, neutral English. " +
    "Base it only on what the article says, never invent facts.\n\n" +
    "DON'T: don't write a Wikipedia-style summary that flatly lists the " +
    "topics the article covers. Add a hook or your own angle (based only " +
    "on what the article says), like you're telling a friend about it " +
    "before they read it.\n\n" +
    "Example of the same article, done badly (too flat) and done well " +
    "(the voice we want):\n\n" +
    "BAD (avoid this tone):\n" +
    "The article explains a six-question framework for navigating career " +
    "transitions, based on over 1,000 interviews and coaching sessions. It " +
    "distinguishes between career progress and progression, and identifies " +
    "four motivations for changing jobs: escaping an untenable situation, " +
    "regaining control, regaining alignment, and taking the next step.\n\n" +
    "GOOD (like this):\n" +
    "If you feel like you need a career change but aren't sure where to, " +
    "this article hands you a map: drawing on over 1,000 interviews and " +
    "hundreds of coaching sessions, the author lays out four typical " +
    "reasons people change careers -- from escaping an impossible boss to " +
    "simply wanting to take the next leap. The core idea: stop chasing " +
    "\"progression\" (climbing the ladder) and start chasing \"progress\" " +
    "(whatever you actually need right now, whether that's autonomy, " +
    "stability, or recognition).\n\n" +
    "Now do the same with the article below.\n\n" +
    "Also identify any book, podcast, or album/song the article explicitly " +
    "mentions. The article below may contain links formatted as " +
    "[link text](url) -- identify which of those links point to another " +
    "article the author explicitly mentions or cites (not navigation, " +
    "social media, \"subscribe\" or other calls to action) and return them " +
    "as an \"article\" mention, with the exact URL of the link. If there " +
    "are no mentions of any kind, return an empty list -- don't invent " +
    "mentions that aren't in the text.\n\n" +
    "Article:\n",
  fr: "Tu es la voix éditoriale de Newsletter Hub : quelqu'un qui s'y " +
    "connaît et qui résume, en un paragraphe, de quoi parle cet article " +
    "pour un ami. Ton business-casual — chaleureux et plein d'esprit, sans " +
    "tomber dans la mièvrerie ni forcer la blague, sans emoji. Écris " +
    "toujours en français neutre et clair. Base-toi uniquement sur ce que " +
    "dit l'article, n'invente jamais de données.\n\n" +
    "À NE PAS FAIRE : n'écris pas un résumé façon Wikipédia qui énumère à " +
    "plat les sujets abordés. Ajoute une accroche ou un angle personnel " +
    "(basé uniquement sur ce que dit l'article), comme si tu le racontais " +
    "à un ami avant qu'il ne le lise.\n\n" +
    "Exemple du même article, en mal (trop plat) et en bien (la voix " +
    "recherchée) :\n\n" +
    "MAL (évite ce ton) :\n" +
    "L'article explique un cadre en six questions pour naviguer les " +
    "transitions de carrière, basé sur plus de 1000 entretiens et séances " +
    "de coaching. Il distingue le progrès de carrière de la progression de " +
    "carrière, et identifie quatre motivations pour changer d'emploi : " +
    "sortir d'une situation intenable, reprendre le contrôle, retrouver " +
    "l'alignement, et passer à l'étape suivante.\n\n" +
    "BIEN (comme ça) :\n" +
    "Si tu sens que tu as besoin de changer de travail mais que tu ne sais " +
    "pas trop vers où, cet article te donne une carte : à partir de plus " +
    "de 1000 entretiens et de centaines de séances de coaching, l'auteur " +
    "dégage quatre raisons typiques de changer de carrière -- de fuir un " +
    "patron impossible à simplement vouloir faire le saut suivant. L'idée " +
    "centrale : arrêter de courir après la \"progression\" (grimper " +
    "l'échelle) et se mettre à chercher le \"progrès\" (ce dont tu as " +
    "vraiment besoin à ce moment de ta vie, que ce soit l'autonomie, la " +
    "stabilité ou la reconnaissance).\n\n" +
    "Fais maintenant la même chose avec l'article ci-dessous.\n\n" +
    "Identifie aussi tout livre, podcast ou album/chanson que l'article " +
    "mentionne explicitement. L'article ci-dessous peut contenir des liens " +
    "au format [texte du lien](url) -- identifie lesquels de ces liens " +
    "correspondent à un autre article que l'auteur mentionne ou cite " +
    "explicitement (pas de liens de navigation, réseaux sociaux, " +
    "\"abonne-toi\" ou autres appels à l'action) et renvoie-les comme une " +
    "mention de type \"article\", avec l'URL exacte du lien. S'il n'y a " +
    "aucune mention d'aucun type, renvoie une liste vide -- n'invente pas " +
    "de mentions absentes du texte.\n\n" +
    "Article :\n",
};

function buildPrompt(
  title: string,
  content: string,
  language: SupportedLanguage,
): string {
  return `${INSTRUCTIONS[language]}${title}\n\n${content}`;
}

const RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    summary: { type: "STRING" },
    mentions: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          type: { type: "STRING", enum: MENTION_TYPES },
          name: { type: "STRING" },
          // Solo se espera con contenido cuando type es "article"; para
          // book/podcast/music el modelo puede omitirlo o devolver "".
          url: { type: "STRING" },
        },
        required: ["type", "name"],
      },
    },
  },
  required: ["summary", "mentions"],
};

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

  // Mismo gate de suscripción que summarize-articles: el resumen de
  // artículo es parte de la misma feature paga (ver proposal.md).
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

  let body: SummarizeArticleRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Body inválido" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  if (typeof body.title !== "string" || typeof body.content !== "string") {
    return new Response(
      JSON.stringify({ error: "Se requiere title y content" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const language = resolveLanguage(body.language);

  const words = countSingleArticleWords({
    title: body.title,
    content: body.content,
  });
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
        {
          role: "user",
          parts: [{ text: buildPrompt(body.title, body.content, language) }],
        },
      ],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 4096,
        thinkingConfig: { thinkingBudget: 0 },
        responseMimeType: "application/json",
        responseSchema: RESPONSE_SCHEMA,
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
  const rawText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof rawText !== "string" || rawText.trim().length === 0) {
    return new Response(
      JSON.stringify({ error: "Respuesta vacía del modelo" }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    );
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(rawText);
  } catch {
    return new Response(
      JSON.stringify({ error: "Respuesta inválida del modelo" }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    );
  }

  const summary = (parsed as Record<string, unknown>)?.summary;
  const mentions = parseMentions((parsed as Record<string, unknown>)?.mentions);
  if (typeof summary !== "string" || summary.trim().length === 0 || !mentions) {
    return new Response(
      JSON.stringify({ error: "Respuesta con formato inesperado del modelo" }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({ summary: summary.trim(), mentions }),
    { headers: { "Content-Type": "application/json" } },
  );
});
