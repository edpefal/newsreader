import { assertEquals, assertStringIncludes } from "jsr:@std/assert@1";
import { buildPrompt, VOICE_INSTRUCTIONS } from "./prompt.ts";

Deno.test("buildPrompt agrupa artículos de la misma fuente en una sola sección", () => {
  const prompt = buildPrompt(
    [
      { title: "Título 1", excerpt: "Extracto 1", sourceName: "Fuente A" },
      { title: "Título 2", excerpt: "Extracto 2", sourceName: "Fuente A" },
      { title: "Título 3", excerpt: "Extracto 3", sourceName: "Fuente B" },
    ],
    "es",
  );

  assertStringIncludes(prompt, "Fuente: Fuente A");
  assertStringIncludes(prompt, "Fuente: Fuente B");
  assertStringIncludes(prompt, "- Título 1: Extracto 1");
  assertStringIncludes(prompt, "- Título 2: Extracto 2");
  assertStringIncludes(prompt, "<articles_content>");
  assertStringIncludes(prompt, "</articles_content>");
});

Deno.test("buildPrompt usa las instrucciones del idioma pedido", () => {
  const promptEn = buildPrompt(
    [{ title: "T", excerpt: "E", sourceName: "S" }],
    "en",
  );
  assertStringIncludes(promptEn, VOICE_INSTRUCTIONS.en);

  const promptFr = buildPrompt(
    [{ title: "T", excerpt: "E", sourceName: "S" }],
    "fr",
  );
  assertStringIncludes(promptFr, VOICE_INSTRUCTIONS.fr);
});

// Mismas conjugaciones de voseo rioplatense que vigila
// test/unit/l10n/neutral_spanish_test.dart en el cliente (con límite de
// palabra, para no confundir "vos" con "voseo") -- el prompt en español
// embebido acá no pasa por ese test, así que se vigila a mano (ver
// CLAUDE.md, regla de español neutro).
const VOSEO_PATTERN =
  /\b(tratá|vos|tenés|podés|sabés|querés|escribís|avisame|agregá|sos)\b/i;

Deno.test("VOICE_INSTRUCTIONS.es no usa voseo rioplatense", () => {
  assertEquals(
    VOSEO_PATTERN.test(VOICE_INSTRUCTIONS.es),
    false,
    "se detectó voseo en VOICE_INSTRUCTIONS.es (debe ser tuteo neutro)",
  );
});
