import { assertEquals } from "jsr:@std/assert@1";
import { articleContentFor, htmlToPlainText, isTruncated } from "./content_selection.ts";

Deno.test("isTruncated: null cuenta como truncado", () => {
  assertEquals(isTruncated(null), true);
});

Deno.test("isTruncated: string vacía o solo espacios cuenta como truncado", () => {
  assertEquals(isTruncated(""), true);
  assertEquals(isTruncated("   "), true);
});

Deno.test("isTruncated: más corto que el umbral cuenta como truncado", () => {
  assertEquals(isTruncated("<p>corto</p>"), true);
});

Deno.test("isTruncated: al menos el umbral de longitud no cuenta como truncado", () => {
  const long = "<p>" + "a".repeat(500) + "</p>";
  assertEquals(isTruncated(long), false);
});

Deno.test("articleContentFor: contenido completo usa el texto plano de content_html", () => {
  const html = "<p>" + "hola mundo ".repeat(60) + "</p>";
  const result = articleContentFor({ content_html: html, excerpt: "excerpt corto" });
  assertEquals(result.includes("hola mundo"), true);
  assertEquals(result.includes("<p>"), false);
});

Deno.test("articleContentFor: contenido truncado cae a excerpt", () => {
  const result = articleContentFor({
    content_html: "<p>corto</p>",
    excerpt: "el excerpt",
  });
  assertEquals(result, "el excerpt");
});

Deno.test("articleContentFor: sin content_html ni excerpt da string vacío", () => {
  const result = articleContentFor({ content_html: null, excerpt: null });
  assertEquals(result, "");
});

Deno.test("htmlToPlainText: remueve tags y decodifica entidades comunes", () => {
  const result = htmlToPlainText("<p>Hola &amp; chau</p>");
  assertEquals(result, "Hola & chau");
});

Deno.test("htmlToPlainText: convierte tags de bloque en saltos de línea", () => {
  const result = htmlToPlainText("<p>Uno</p><p>Dos</p>");
  assertEquals(result, "Uno\nDos");
});

Deno.test("htmlToPlainText: remueve bloques de script y style", () => {
  const result = htmlToPlainText(
    "<style>.a{color:red}</style><p>Texto</p><script>alert(1)</script>",
  );
  assertEquals(result, "Texto");
});
