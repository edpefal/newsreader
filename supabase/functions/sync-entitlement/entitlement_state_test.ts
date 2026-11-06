import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import {
  fetchEntitlementActive,
  isEntitlementActive,
  RevenueCatApiError,
  type SubscriberResponse,
} from "./entitlement_state.ts";

const now = new Date("2026-10-29T12:00:00Z");

function withPro(entitlement: Record<string, unknown>): SubscriberResponse {
  return {
    subscriber: { entitlements: { pro: entitlement } },
  } as unknown as SubscriberResponse;
}

Deno.test("vigente: expires_date futuro", () => {
  assertEquals(
    isEntitlementActive(withPro({ expires_date: "2026-11-29T12:00:00Z" }), now),
    true,
  );
});

Deno.test("expirado: expires_date pasado", () => {
  assertEquals(
    isEntitlementActive(withPro({ expires_date: "2026-10-28T12:00:00Z" }), now),
    false,
  );
});

Deno.test("prueba gratis vigente cuenta como activa", () => {
  // La prueba es una suscripción con periodo de prueba cuyo vencimiento aún
  // no llega: el entitlement la refleja con `expires_date` futuro.
  assertEquals(
    isEntitlementActive(
      withPro({
        expires_date: "2026-11-05T12:00:00Z",
        purchase_date: "2026-10-29T12:00:00Z",
      }),
      now,
    ),
    true,
  );
});

Deno.test("sin entitlement pro: no activo", () => {
  assertEquals(
    isEntitlementActive({ subscriber: { entitlements: {} } }, now),
    false,
  );
  assertEquals(isEntitlementActive({ subscriber: {} }, now), false);
  assertEquals(isEntitlementActive({}, now), false);
});

Deno.test("expires_date nulo es acceso sin vencimiento", () => {
  assertEquals(isEntitlementActive(withPro({ expires_date: null }), now), true);
});

Deno.test("periodo de gracia vigente mantiene el acceso", () => {
  assertEquals(
    isEntitlementActive(
      withPro({
        expires_date: "2026-10-28T12:00:00Z",
        grace_period_expires_date: "2026-10-31T12:00:00Z",
      }),
      now,
    ),
    true,
  );
});

Deno.test("fetchEntitlementActive consulta con la clave secreta y el id codificado", async () => {
  let requested: { url: string; auth: string | null } | null = null;
  const fetchFn = ((url: string, init: RequestInit) => {
    requested = {
      url,
      auth: new Headers(init.headers).get("Authorization"),
    };
    return Promise.resolve(
      new Response(
        JSON.stringify(withPro({ expires_date: "2026-11-29T12:00:00Z" })),
      ),
    );
  }) as typeof fetch;

  const active = await fetchEntitlementActive({
    appUserId: "user/1",
    secretKey: "sk_test",
    fetchFn,
    now,
  });

  assertEquals(active, true);
  assertEquals(
    requested,
    {
      url: "https://api.revenuecat.com/v1/subscribers/user%2F1",
      auth: "Bearer sk_test",
    },
  );
});

Deno.test("error de API: lanza RevenueCatApiError", async () => {
  const fetchFn =
    (() =>
      Promise.resolve(new Response("{}", { status: 500 }))) as typeof fetch;
  await assertRejects(
    () =>
      fetchEntitlementActive({
        appUserId: "u",
        secretKey: "sk",
        fetchFn,
      }),
    RevenueCatApiError,
  );
});

Deno.test("sin red: lanza RevenueCatApiError", async () => {
  const fetchFn =
    (() => Promise.reject(new TypeError("network"))) as typeof fetch;
  await assertRejects(
    () =>
      fetchEntitlementActive({
        appUserId: "u",
        secretKey: "sk",
        fetchFn,
      }),
    RevenueCatApiError,
  );
});
