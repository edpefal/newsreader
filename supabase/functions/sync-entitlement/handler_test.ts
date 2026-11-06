import { assertEquals } from "jsr:@std/assert@1";
import { handleSync, type SyncDeps } from "./handler.ts";
import { RevenueCatApiError } from "./entitlement_state.ts";

const USER_ID = "0b0d3c5e-6f0e-4f0a-9d3e-1c2b3a4d5e6f";
const OTHER_USER_ID = "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d";

interface Calls {
  fetchActive: string[];
  upserts: { userId: string; isActive: boolean }[];
}

function makeDeps(
  overrides: Partial<SyncDeps> = {},
): { deps: SyncDeps; calls: Calls } {
  const calls: Calls = { fetchActive: [], upserts: [] };
  const deps: SyncDeps = {
    authenticate: (token) =>
      Promise.resolve(token === "token-valido" ? USER_ID : null),
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
  { authorization, body, method = "POST" }: {
    authorization?: string;
    body?: unknown;
    method?: string;
  } = {},
): Request {
  const headers = new Headers();
  if (authorization) headers.set("Authorization", authorization);
  return new Request("https://example.test/sync-entitlement", {
    method,
    headers,
    body: method === "POST" ? JSON.stringify(body ?? {}) : undefined,
  });
}

Deno.test("sin sesión: 401 sin consultar ni escribir", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleSync(request(), deps);
  assertEquals(res.status, 401);
  assertEquals(calls.fetchActive, []);
  assertEquals(calls.upserts, []);
});

Deno.test("token inválido: 401 sin consultar ni escribir", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleSync(
    request({ authorization: "Bearer token-falso" }),
    deps,
  );
  assertEquals(res.status, 401);
  assertEquals(calls.fetchActive, []);
  assertEquals(calls.upserts, []);
});

Deno.test("método distinto de POST: 405", async () => {
  const { deps } = makeDeps();
  const res = await handleSync(request({ method: "GET" }), deps);
  assertEquals(res.status, 405);
});

Deno.test("usuario suscrito: upsert is_active = true del usuario del token", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleSync(
    request({ authorization: "Bearer token-valido" }),
    deps,
  );
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { is_active: true });
  assertEquals(calls.fetchActive, [USER_ID]);
  assertEquals(calls.upserts, [{ userId: USER_ID, isActive: true }]);
});

Deno.test("usuario sin acceso vigente: upsert is_active = false", async () => {
  const { deps, calls } = makeDeps({
    fetchEntitlementActive: () => Promise.resolve(false),
  });
  const res = await handleSync(
    request({ authorization: "Bearer token-valido" }),
    deps,
  );
  assertEquals(res.status, 200);
  assertEquals(calls.upserts, [{ userId: USER_ID, isActive: false }]);
});

Deno.test("ignora un user_id del body: solo toca al usuario de la sesión", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleSync(
    request({
      authorization: "Bearer token-valido",
      body: { user_id: OTHER_USER_ID, userId: OTHER_USER_ID },
    }),
    deps,
  );
  assertEquals(res.status, 200);
  assertEquals(calls.fetchActive, [USER_ID]);
  assertEquals(calls.upserts, [{ userId: USER_ID, isActive: true }]);
});

Deno.test("falla RevenueCat: 500 sin modificar entitlements", async () => {
  const { deps, calls } = makeDeps({
    fetchEntitlementActive: () =>
      Promise.reject(new RevenueCatApiError("RevenueCat respondió 500")),
  });
  const res = await handleSync(
    request({ authorization: "Bearer token-valido" }),
    deps,
  );
  assertEquals(res.status, 500);
  assertEquals(calls.upserts, []);
});
