import { assertEquals } from "jsr:@std/assert@1";
import { deleteRevenueCatCustomer } from "./revenuecat.ts";

const USER_ID = "0b0d3c5e-6f0e-4f0a-9d3e-1c2b3a4d5e6f";

Deno.test("borra al cliente con DELETE y la clave secreta", async () => {
  let requested: { url: string; method?: string; auth: string | null } | null =
    null;
  const fetchFn = ((url: string, init: RequestInit) => {
    requested = {
      url,
      method: init.method,
      auth: new Headers(init.headers).get("Authorization"),
    };
    return Promise.resolve(new Response("{}", { status: 200 }));
  }) as typeof fetch;

  const ok = await deleteRevenueCatCustomer({
    appUserId: USER_ID,
    secretKey: "sk_test",
    fetchFn,
  });

  assertEquals(ok, true);
  assertEquals(requested, {
    url: `https://api.revenuecat.com/v1/subscribers/${USER_ID}`,
    method: "DELETE",
    auth: "Bearer sk_test",
  });
});

Deno.test("404 se trata como ya borrado", async () => {
  const fetchFn =
    (() =>
      Promise.resolve(new Response("{}", { status: 404 }))) as typeof fetch;
  const ok = await deleteRevenueCatCustomer({
    appUserId: USER_ID,
    secretKey: "sk",
    fetchFn,
  });
  assertEquals(ok, true);
});

Deno.test("error de la API: no lanza, devuelve false y registra sin PII", async () => {
  const logs: string[] = [];
  const fetchFn =
    (() =>
      Promise.resolve(new Response("{}", { status: 500 }))) as typeof fetch;

  const ok = await deleteRevenueCatCustomer({
    appUserId: USER_ID,
    secretKey: "sk",
    fetchFn,
    logError: (m) => logs.push(m),
  });

  assertEquals(ok, false);
  assertEquals(logs.length, 1);
  assertEquals(logs[0].includes(USER_ID), false);
});

Deno.test("error de red: no lanza, devuelve false y registra sin PII", async () => {
  const logs: string[] = [];
  const fetchFn =
    (() =>
      Promise.reject(new TypeError(`fallo con ${USER_ID}`))) as typeof fetch;

  const ok = await deleteRevenueCatCustomer({
    appUserId: USER_ID,
    secretKey: "sk",
    fetchFn,
    logError: (m) => logs.push(m),
  });

  assertEquals(ok, false);
  assertEquals(logs.length, 1);
  assertEquals(logs[0].includes(USER_ID), false);
});

Deno.test("sin clave secreta: no llama a la API, devuelve false y registra", async () => {
  const logs: string[] = [];
  let called = false;
  const fetchFn = (() => {
    called = true;
    return Promise.resolve(new Response("{}"));
  }) as typeof fetch;

  const ok = await deleteRevenueCatCustomer({
    appUserId: USER_ID,
    secretKey: undefined,
    fetchFn,
    logError: (m) => logs.push(m),
  });

  assertEquals(ok, false);
  assertEquals(called, false);
  assertEquals(logs.length, 1);
});
