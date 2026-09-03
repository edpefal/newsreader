import { assertEquals } from "jsr:@std/assert@1";
import { hasFreeUsageAvailable } from "./free_usage.ts";

Deno.test("hay cupo disponible sin fila previa", () => {
  assertEquals(hasFreeUsageAvailable(null), true);
});

Deno.test("hay cupo disponible con used = false", () => {
  assertEquals(hasFreeUsageAvailable({ used: false }), true);
});

Deno.test("no hay cupo disponible con used = true", () => {
  assertEquals(hasFreeUsageAvailable({ used: true }), false);
});
