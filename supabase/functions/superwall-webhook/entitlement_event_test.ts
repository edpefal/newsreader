import { assertEquals } from "jsr:@std/assert@1";
import { resolveIsActive } from "./entitlement_event.ts";

Deno.test("initial_purchase otorga acceso", () => {
  assertEquals(resolveIsActive({ type: "initial_purchase" }), true);
});

Deno.test("renewal otorga acceso", () => {
  assertEquals(resolveIsActive({ type: "renewal" }), true);
});

Deno.test("uncancellation otorga acceso", () => {
  assertEquals(resolveIsActive({ type: "uncancellation" }), true);
});

Deno.test("cancellation no revoca acceso (solo apaga auto-renew, el usuario sigue con acceso hasta expiration)", () => {
  assertEquals(resolveIsActive({ type: "cancellation" }), null);
});

Deno.test("expiration revoca acceso", () => {
  assertEquals(resolveIsActive({ type: "expiration" }), false);
});

Deno.test("billing_issue revoca acceso", () => {
  assertEquals(resolveIsActive({ type: "billing_issue" }), false);
});

Deno.test("evento desconocido se ignora (null)", () => {
  assertEquals(resolveIsActive({ type: "algo_no_reconocido" }), null);
});

Deno.test("renewal con price negativo (reembolso) revoca acceso", () => {
  assertEquals(
    resolveIsActive({ type: "renewal", data: { price: -9.99 } }),
    false,
  );
});

Deno.test("initial_purchase con proceeds negativo revoca acceso", () => {
  assertEquals(
    resolveIsActive({ type: "initial_purchase", data: { proceeds: -1 } }),
    false,
  );
});
