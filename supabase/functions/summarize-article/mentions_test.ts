import { assertEquals } from "jsr:@std/assert@1";
import { parseMentions } from "./mentions.ts";

Deno.test("parsea una lista válida de menciones", () => {
  const mentions = parseMentions([
    { type: "book", name: "Project Hail Mary" },
    { type: "podcast", name: "Radiolab" },
    { type: "music", name: "Random Access Memories" },
  ]);
  assertEquals(mentions, [
    { type: "book", name: "Project Hail Mary" },
    { type: "podcast", name: "Radiolab" },
    { type: "music", name: "Random Access Memories" },
  ]);
});

Deno.test("una lista vacía es válida", () => {
  assertEquals(parseMentions([]), []);
});

Deno.test("rechaza si no es un array", () => {
  assertEquals(parseMentions({ type: "book", name: "X" }), null);
  assertEquals(parseMentions(null), null);
  assertEquals(parseMentions(undefined), null);
});

Deno.test("rechaza un tipo de mención no soportado", () => {
  assertEquals(parseMentions([{ type: "product", name: "iPhone" }]), null);
});

Deno.test("rechaza un item sin name", () => {
  assertEquals(parseMentions([{ type: "book" }]), null);
});

Deno.test("rechaza si un solo item del array es inválido", () => {
  assertEquals(
    parseMentions([
      { type: "book", name: "Válido" },
      { type: "invalid", name: "Inválido" },
    ]),
    null,
  );
});

Deno.test("parsea una mención de tipo article con url", () => {
  const mentions = parseMentions([
    { type: "article", name: "Otro artículo", url: "https://example.com/x" },
  ]);
  assertEquals(mentions, [
    { type: "article", name: "Otro artículo", url: "https://example.com/x" },
  ]);
});

Deno.test("rechaza una mención de tipo article sin url", () => {
  assertEquals(
    parseMentions([{ type: "article", name: "Otro artículo" }]),
    null,
  );
});

Deno.test("rechaza una mención de tipo article con url vacía", () => {
  assertEquals(
    parseMentions([{ type: "article", name: "Otro artículo", url: "" }]),
    null,
  );
  assertEquals(
    parseMentions([{ type: "article", name: "Otro artículo", url: "   " }]),
    null,
  );
});

Deno.test("no exige url para tipos book/podcast/music", () => {
  const mentions = parseMentions([{ type: "book", name: "Un libro" }]);
  assertEquals(mentions, [{ type: "book", name: "Un libro" }]);
});
