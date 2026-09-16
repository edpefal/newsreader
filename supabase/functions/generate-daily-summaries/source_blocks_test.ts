import { assertEquals } from "jsr:@std/assert@1";
import { buildSourceBlocks } from "./source_blocks.ts";

Deno.test("agrupa artículos de la misma fuente en un solo bloque", () => {
  const blocks = buildSourceBlocks([
    { id: "a1", source_id: "s1", source_name: "Fuente 1" },
    { id: "a2", source_id: "s1", source_name: "Fuente 1" },
  ]);
  assertEquals(blocks, [
    { sourceId: "s1", sourceName: "Fuente 1", articleIds: ["a1", "a2"] },
  ]);
});

Deno.test("crea un bloque por cada fuente distinta, en orden de primera aparición", () => {
  const blocks = buildSourceBlocks([
    { id: "a1", source_id: "s1", source_name: "Fuente 1" },
    { id: "a2", source_id: "s2", source_name: "Fuente 2" },
    { id: "a3", source_id: "s1", source_name: "Fuente 1" },
  ]);
  assertEquals(blocks, [
    { sourceId: "s1", sourceName: "Fuente 1", articleIds: ["a1", "a3"] },
    { sourceId: "s2", sourceName: "Fuente 2", articleIds: ["a2"] },
  ]);
});

Deno.test("sin artículos da una lista vacía", () => {
  assertEquals(buildSourceBlocks([]), []);
});
