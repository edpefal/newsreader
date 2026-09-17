import { assertEquals } from "jsr:@std/assert@1";
import { isBackgroundInvocation } from "./background_mode.ts";

Deno.test("acepta modo background con el token de service_role correcto", () => {
  assertEquals(
    isBackgroundInvocation("secret-key", "secret-key", "background"),
    true,
  );
});

Deno.test("rechaza modo background con un token que no es el de service_role (ej. JWT de usuario)", () => {
  assertEquals(
    isBackgroundInvocation("un-jwt-de-usuario", "secret-key", "background"),
    false,
  );
});

Deno.test("rechaza si el body no pide exactamente mode='background'", () => {
  assertEquals(isBackgroundInvocation("secret-key", "secret-key", undefined), false);
  assertEquals(
    isBackgroundInvocation("secret-key", "secret-key", "on-demand"),
    false,
  );
});

Deno.test("rechaza si mode no vino como string", () => {
  assertEquals(isBackgroundInvocation("secret-key", "secret-key", 1), false);
  assertEquals(isBackgroundInvocation("secret-key", "secret-key", null), false);
});

Deno.test("un service_role key correcto sin pedir mode background no activa el modo background", () => {
  assertEquals(isBackgroundInvocation("secret-key", "secret-key", undefined), false);
});
