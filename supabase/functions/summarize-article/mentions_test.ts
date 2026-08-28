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
