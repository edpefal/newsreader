import { assertEquals } from "jsr:@std/assert@1";
import { countSingleArticleWords } from "./word_count.ts";

Deno.test("cuenta las palabras de título y contenido", () => {
  const words = countSingleArticleWords({
    title: "Dos palabras",
    content: "Tres palabras más",
  });
  assertEquals(words, 5);
});

Deno.test("ignora espacios múltiples y de más al contar", () => {
  const words = countSingleArticleWords({
    title: "  Uno   dos  ",
    content: "tres",
  });
  assertEquals(words, 3);
});

Deno.test("un content vacío no suma palabras", () => {
  const words = countSingleArticleWords({
    title: "Solo título",
    content: "",
  });
  assertEquals(words, 2);
});
