import { assertEquals } from "jsr:@std/assert@1";
import { handleWebhook, type WebhookDeps } from "./handler.ts";
import { RevenueCatApiError } from "./entitlement_state.ts";
import { secureEqual } from "./secure_equal.ts";

const USER_ID = "0b0d3c5e-6f0e-4f0a-9d3e-1c2b3a4d5e6f";
const SECRET = "valor-de-autorizacion";

interface Calls {
  userExists: string[];
  fetchActive: string[];
  upserts: { userId: string; isActive: boolean }[];
}

function makeDeps(
  overrides: Partial<WebhookDeps> = {},
): { deps: WebhookDeps; calls: Calls } {
  const calls: Calls = { userExists: [], fetchActive: [], upserts: [] };
  const deps: WebhookDeps = {
    authSecret: SECRET,
    userExists: (id) => {
      calls.userExists.push(id);
      return Promise.resolve(true);
    },
    fetchEntitlementActive: (id) => {
      calls.fetchActive.push(id);
      return Promise.resolve(true);
    },
    upsertEntitlement: (userId, isActive) => {
      calls.upserts.push({ userId, isActive });
      return Promise.resolve();
    },
    ...overrides,
  };
  return { deps, calls };
}

function request(
  body: unknown,
  { authorization = SECRET, method = "POST" } = {},
): Request {
  return new Request("https://example.test/revenuecat-webhook", {
    method,
    headers: { Authorization: authorization },
    body: method === "POST" ? JSON.stringify(body) : undefined,
  });
}

const eventFor = (appUserId: unknown, type = "INITIAL_PURCHASE") => ({
  event: { type, app_user_id: appUserId },
});

Deno.test("secureEqual compara por valor", async () => {
  assertEquals(await secureEqual("abc", "abc"), true);
  assertEquals(await secureEqual("abc", "abd"), false);
  assertEquals(await secureEqual("abc", "abcd"), false);
  assertEquals(await secureEqual("", "abc"), false);
});

Deno.test("autorización incorrecta: 401 sin consultar ni escribir", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleWebhook(
    request(eventFor(USER_ID), { authorization: "otro" }),
    deps,
  );
  assertEquals(res.status, 401);
  assertEquals(calls.userExists, []);
  assertEquals(calls.fetchActive, []);
  assertEquals(calls.upserts, []);
});

Deno.test("sin cabecera Authorization: 401", async () => {
  const { deps } = makeDeps();
  const res = await handleWebhook(
    request(eventFor(USER_ID), { authorization: "" }),
    deps,
  );
  assertEquals(res.status, 401);
});

Deno.test("método distinto de POST: 405", async () => {
  const { deps } = makeDeps();
  const res = await handleWebhook(request(null, { method: "GET" }), deps);
  assertEquals(res.status, 405);
});

Deno.test("usuario con entitlement vigente: upsert is_active = true", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleWebhook(request(eventFor(USER_ID)), deps);
  assertEquals(res.status, 200);
  assertEquals(calls.upserts, [{ userId: USER_ID, isActive: true }]);
});

Deno.test("entitlement no vigente: upsert is_active = false", async () => {
  const { deps, calls } = makeDeps({
    fetchEntitlementActive: () => Promise.resolve(false),
  });
  const res = await handleWebhook(
    request(eventFor(USER_ID, "EXPIRATION")),
    deps,
  );
  assertEquals(res.status, 200);
  assertEquals(calls.upserts, [{ userId: USER_ID, isActive: false }]);
});

Deno.test("el resultado no depende del tipo de evento", async () => {
  // Una cancelación con el periodo pagado aún vigente no revoca el acceso:
  // el estado sale de la consulta, no del tipo.
  const { deps, calls } = makeDeps();
  await handleWebhook(request(eventFor(USER_ID, "CANCELLATION")), deps);
  assertEquals(calls.upserts, [{ userId: USER_ID, isActive: true }]);
});

Deno.test("id anónimo de RevenueCat: 200 sin consultar ni escribir", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleWebhook(
    request(eventFor("$RCAnonymousID:abc123")),
    deps,
  );
  assertEquals(res.status, 200);
  assertEquals(calls.userExists, []);
  assertEquals(calls.fetchActive, []);
  assertEquals(calls.upserts, []);
});

Deno.test("evento sin app_user_id: 200 sin escribir", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleWebhook(request({ event: { type: "TEST" } }), deps);
  assertEquals(res.status, 200);
  assertEquals(calls.fetchActive, []);
  assertEquals(calls.upserts, []);
});

Deno.test("id que no es uuid: 200 sin escribir", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleWebhook(request(eventFor("no-es-uuid")), deps);
  assertEquals(res.status, 200);
  assertEquals(calls.userExists, []);
  assertEquals(calls.upserts, []);
});

Deno.test("usuario inexistente en este proyecto: 200 sin consultar ni escribir", async () => {
  const { deps, calls } = makeDeps({
    userExists: () => Promise.resolve(false),
  });
  const res = await handleWebhook(request(eventFor(USER_ID)), deps);
  assertEquals(res.status, 200);
  assertEquals(calls.fetchActive, []);
  assertEquals(calls.upserts, []);
});

Deno.test("falla RevenueCat: 500 sin modificar entitlements", async () => {
  const { deps, calls } = makeDeps({
    fetchEntitlementActive: () =>
      Promise.reject(new RevenueCatApiError("RevenueCat respondió 500")),
  });
  const res = await handleWebhook(request(eventFor(USER_ID)), deps);
  assertEquals(res.status, 500);
  assertEquals(calls.upserts, []);
});

Deno.test("falla al escribir entitlements: 500", async () => {
  const { deps } = makeDeps({
    upsertEntitlement: () => Promise.reject(new Error("db caída")),
  });
  const res = await handleWebhook(request(eventFor(USER_ID)), deps);
  assertEquals(res.status, 500);
});

Deno.test("body que no es JSON: 400", async () => {
  const { deps } = makeDeps();
  const req = new Request("https://example.test/revenuecat-webhook", {
    method: "POST",
    headers: { Authorization: SECRET },
    body: "no-json",
  });
  const res = await handleWebhook(req, deps);
  assertEquals(res.status, 400);
});
