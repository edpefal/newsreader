import { assertEquals } from "jsr:@std/assert@1";
import { hasActiveEntitlement } from "./entitlement.ts";

Deno.test("rechaza sin fila en entitlements", () => {
  assertEquals(hasActiveEntitlement(null), false);
});

Deno.test("rechaza con is_active = false", () => {
  assertEquals(hasActiveEntitlement({ is_active: false }), false);
});

Deno.test("acepta con is_active = true", () => {
  assertEquals(hasActiveEntitlement({ is_active: true }), true);
});
