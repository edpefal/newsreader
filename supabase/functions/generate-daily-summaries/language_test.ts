import { assertEquals } from "jsr:@std/assert@1";
import { resolveLanguage } from "./language.ts";

Deno.test("acepta 'en' como idioma soportado", () => {
  assertEquals(resolveLanguage("en"), "en");
});

Deno.test("acepta 'es' como idioma soportado", () => {
  assertEquals(resolveLanguage("es"), "es");
});

Deno.test("acepta 'fr' como idioma soportado", () => {
  assertEquals(resolveLanguage("fr"), "fr");
});

Deno.test("cae a 'en' con un idioma no soportado", () => {
  assertEquals(resolveLanguage("de"), "en");
});

Deno.test("cae a 'en' si el idioma está ausente", () => {
  assertEquals(resolveLanguage(undefined), "en");
});

Deno.test("cae a 'en' si el idioma no es un string", () => {
  assertEquals(resolveLanguage(123), "en");
});
