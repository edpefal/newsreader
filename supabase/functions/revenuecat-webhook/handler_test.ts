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

// --- Traspaso de suscripción (TRANSFER): sin app_user_id, con listas de usuarios

const ORIGIN_ID = "11111111-1111-4111-8111-111111111111";
const DEST_ID = "22222222-2222-4222-8222-222222222222";

const transferEvent = (from: unknown, to: unknown) => ({
  event: {
    type: "TRANSFER",
    transferred_from: from,
    transferred_to: to,
  },
});

/** Estado vigente que informa RevenueCat para cada usuario. */
function depsWithStates(
  states: Record<string, boolean>,
  overrides: Partial<WebhookDeps> = {},
) {
  const made = makeDeps(overrides);
  if (!overrides.fetchEntitlementActive) {
    made.deps.fetchEntitlementActive = (id) => {
      made.calls.fetchActive.push(id);
      return Promise.resolve(states[id] ?? false);
    };
  }
  return made;
}

Deno.test("traspaso: el origen pierde el acceso y el destino lo recibe", async () => {
  const { deps, calls } = depsWithStates({
    [ORIGIN_ID]: false,
    [DEST_ID]: true,
  });
  const res = await handleWebhook(
    request(transferEvent([ORIGIN_ID], [DEST_ID])),
    deps,
  );
  assertEquals(res.status, 200);
  assertEquals(
    calls.upserts.sort((a, b) => a.userId.localeCompare(b.userId)),
    [
      { userId: ORIGIN_ID, isActive: false },
      { userId: DEST_ID, isActive: true },
    ],
  );
});

Deno.test("traspaso: el estado sale de RevenueCat, no de ser origen o destino", async () => {
  // Si el origen conserva otra suscripción vigente, sigue activo.
  const { deps, calls } = depsWithStates({
    [ORIGIN_ID]: true,
    [DEST_ID]: true,
  });
  await handleWebhook(request(transferEvent([ORIGIN_ID], [DEST_ID])), deps);
  assertEquals(calls.upserts.every((u) => u.isActive), true);
});

Deno.test("traspaso: ignora anónimos, no-uuid e inexistentes y sincroniza a los demás", async () => {
  const GHOST_ID = "33333333-3333-4333-8333-333333333333";
  const { deps, calls } = depsWithStates(
    { [DEST_ID]: true },
    {
      userExists: (id) => {
        calls.userExists.push(id);
        return Promise.resolve(id !== GHOST_ID);
      },
    },
  );
  const res = await handleWebhook(
    request(
      transferEvent(
        ["$RCAnonymousID:abc", "no-es-uuid", GHOST_ID],
        [DEST_ID],
      ),
    ),
    deps,
  );
  assertEquals(res.status, 200);
  assertEquals(calls.upserts, [{ userId: DEST_ID, isActive: true }]);
  assertEquals(calls.fetchActive, [DEST_ID]);
});

Deno.test("traspaso: si falla uno responde 500 pero sincroniza al otro", async () => {
  const { deps, calls } = depsWithStates(
    { [DEST_ID]: true },
    {
      fetchEntitlementActive: (id) => {
        if (id === ORIGIN_ID) {
          return Promise.reject(
            new RevenueCatApiError("RevenueCat respondió 500"),
          );
        }
        calls.fetchActive.push(id);
        return Promise.resolve(true);
      },
    },
  );
  const res = await handleWebhook(
    request(transferEvent([ORIGIN_ID], [DEST_ID])),
    deps,
  );
  assertEquals(res.status, 500);
  assertEquals(calls.upserts, [{ userId: DEST_ID, isActive: true }]);
});

Deno.test("traspaso: falla al escribir uno responde 500 e intenta el otro", async () => {
  const attempted: string[] = [];
  const { deps } = depsWithStates(
    { [ORIGIN_ID]: false, [DEST_ID]: true },
    {
      upsertEntitlement: (userId) => {
        attempted.push(userId);
        return userId === ORIGIN_ID
          ? Promise.reject(new Error("db caída"))
          : Promise.resolve();
      },
    },
  );
  const res = await handleWebhook(
    request(transferEvent([ORIGIN_ID], [DEST_ID])),
    deps,
  );
  assertEquals(res.status, 500);
  assertEquals(attempted.sort(), [ORIGIN_ID, DEST_ID].sort());
});

Deno.test("traspaso: reenviarlo deja el mismo estado, sin duplicar", async () => {
  const states = { [ORIGIN_ID]: false, [DEST_ID]: true };
  const { deps, calls } = depsWithStates(states);
  const event = transferEvent([ORIGIN_ID], [DEST_ID]);
  await handleWebhook(request(event), deps);
  await handleWebhook(request(event), deps);
  // Dos entregas: cada una escribe el estado vigente de cada usuario.
  assertEquals(calls.upserts.length, 4);
  const lastByUser = new Map(calls.upserts.map((u) => [u.userId, u.isActive]));
  assertEquals(lastByUser.get(ORIGIN_ID), false);
  assertEquals(lastByUser.get(DEST_ID), true);
});

Deno.test("traspaso: un usuario repetido en ambas listas se procesa una vez", async () => {
  const { deps, calls } = depsWithStates({ [DEST_ID]: true });
  await handleWebhook(request(transferEvent([DEST_ID], [DEST_ID])), deps);
  assertEquals(calls.fetchActive, [DEST_ID]);
});

Deno.test("traspaso con listas que no son arreglos: 200 sin consultar ni escribir", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleWebhook(
    request(transferEvent("no-es-lista", { 0: DEST_ID })),
    deps,
  );
  assertEquals(res.status, 200);
  assertEquals(calls.userExists, []);
  assertEquals(calls.fetchActive, []);
  assertEquals(calls.upserts, []);
});

Deno.test("evento sin app_user_id ni listas: 200 sin consultar ni escribir", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleWebhook(
    request({ event: { type: "TEST" } }),
    deps,
  );
  assertEquals(res.status, 200);
  assertEquals(calls.fetchActive, []);
  assertEquals(calls.upserts, []);
});

Deno.test("traspaso sin la autorización correcta: 401 sin consultar ni escribir", async () => {
  const { deps, calls } = makeDeps();
  const res = await handleWebhook(
    request(transferEvent([ORIGIN_ID], [DEST_ID]), { authorization: "otro" }),
    deps,
  );
  assertEquals(res.status, 401);
  assertEquals(calls.userExists, []);
  assertEquals(calls.fetchActive, []);
  assertEquals(calls.upserts, []);
});

Deno.test("evento normal con app_user_id: sigue sincronizando solo a ese usuario", async () => {
  const { deps, calls } = makeDeps();
  await handleWebhook(
    request({
      event: {
        type: "RENEWAL",
        app_user_id: DEST_ID,
        transferred_from: [ORIGIN_ID],
      },
    }),
    deps,
  );
  assertEquals(calls.fetchActive, [DEST_ID]);
});
