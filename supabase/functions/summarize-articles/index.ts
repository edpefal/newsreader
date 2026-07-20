// Proxy a la API de Gemini para el resumen diario de Newsletter Hub.
// La app Flutter llama a esta función (autenticada con el anon key de
// Supabase, nunca con la API key de Gemini) para que la key real de Gemini
// jamás quede embebida en el APK/IPA distribuido.
import "@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_MODEL = "gemini-2.5-flash";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

interface ArticleExcerpt {
  title: string;
  excerpt: string;
  sourceName: string;
}

interface SummarizeRequest {
  articles: ArticleExcerpt[];
}

// Agrupa por fuente y arma un prompt que le pide a Gemini un párrafo por
// fuente, usando el nombre EXACTO que le pasamos (no lo inventa). Se hace
// en una sola llamada (en vez de una por fuente) por la cuota ajustada del
// free tier de Gemini (20 requests/día).
function buildPrompt(articles: ArticleExcerpt[]): string {
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

  return (
    "A continuación hay noticias del día agrupadas por fuente. Para cada " +
    "fuente, escribí un párrafo breve en español resumiendo sus noticias.\n\n" +
    "Formato de salida EXACTO, sin desviarte:\n" +
    "- Por cada fuente: una línea con el nombre de la fuente tal cual " +
    'aparece abajo (sin la palabra "Fuente:", sin markdown, sin asteriscos), ' +
    "y en la línea siguiente el párrafo de resumen.\n" +
    "- Dejá una línea en blanco entre cada fuente.\n" +
    "- No agregues encabezados, introducciones, listas ni texto fuera de ese formato.\n\n" +
    sections
  );
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Método no permitido" }),
      { status: 405, headers: { "Content-Type": "application/json" } },
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
      contents: [{ role: "user", parts: [{ text: buildPrompt(articles) }] }],
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
