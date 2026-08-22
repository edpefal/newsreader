import { assertEquals } from "jsr:@std/assert@1";
import { countArticleWords } from "./word_count.ts";

Deno.test("cuenta las palabras de título y contenido de un solo artículo", () => {
  const words = countArticleWords([
    { title: "Dos palabras", excerpt: "Tres palabras más", sourceName: "A" },
  ]);
  assertEquals(words, 5);
});

Deno.test("suma las palabras de varios artículos", () => {
  const words = countArticleWords([
    { title: "Uno dos", excerpt: "tres", sourceName: "A" },
    { title: "Cuatro", excerpt: "cinco seis siete", sourceName: "B" },
  ]);
  assertEquals(words, 7);
});

Deno.test("ignora espacios múltiples y de más al contar", () => {
  const words = countArticleWords([
    { title: "  Uno   dos  ", excerpt: "tres", sourceName: "A" },
  ]);
  assertEquals(words, 3);
});

Deno.test("un excerpt vacío no suma palabras", () => {
  const words = countArticleWords([
    { title: "Solo título", excerpt: "", sourceName: "A" },
  ]);
  assertEquals(words, 2);
});

Deno.test("lista vacía de artículos da 0 palabras", () => {
  assertEquals(countArticleWords([]), 0);
});
