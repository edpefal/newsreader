import { assertEquals } from "jsr:@std/assert@1";
import { MAX_EVENT_USERS, resolveEventUsers } from "./event_users.ts";

Deno.test("evento normal: el app_user_id", () => {
  assertEquals(resolveEventUsers({ type: "RENEWAL", app_user_id: "u1" }), {
    userIds: ["u1"],
    truncated: false,
  });
});

Deno.test("traspaso: origen y destino", () => {
  assertEquals(
    resolveEventUsers({
      type: "TRANSFER",
      transferred_from: ["a"],
      transferred_to: ["b"],
    }),
    { userIds: ["a", "b"], truncated: false },
  );
});

Deno.test("traspaso: varios en cada lista, sin duplicados", () => {
  assertEquals(
    resolveEventUsers({
      transferred_from: ["a", "b"],
      transferred_to: ["b", "c"],
    }).userIds,
    ["a", "b", "c"],
  );
});

Deno.test("app_user_id tiene prioridad sobre las listas", () => {
  assertEquals(
    resolveEventUsers({
      app_user_id: "u1",
      transferred_from: ["a"],
      transferred_to: ["b"],
    }).userIds,
    ["u1"],
  );
});

Deno.test("solo una de las listas", () => {
  assertEquals(resolveEventUsers({ transferred_to: ["b"] }).userIds, ["b"]);
  assertEquals(resolveEventUsers({ transferred_from: ["a"] }).userIds, ["a"]);
});

Deno.test("listas que no son arreglos se ignoran", () => {
  assertEquals(
    resolveEventUsers({ transferred_from: "a", transferred_to: { 0: "b" } }),
    { userIds: [], truncated: false },
  );
});

Deno.test("elementos que no son strings se descartan", () => {
  assertEquals(
    resolveEventUsers({
      transferred_from: ["a", 1, null, "", { id: "x" }],
      transferred_to: [true, "b"],
    }).userIds,
    ["a", "b"],
  );
});

Deno.test("sin app_user_id ni listas: vacío", () => {
  assertEquals(resolveEventUsers({ type: "TEST" }), {
    userIds: [],
    truncated: false,
  });
});

Deno.test("app_user_id vacío o que no es string: se ignora", () => {
  assertEquals(resolveEventUsers({ app_user_id: "" }).userIds, []);
  assertEquals(resolveEventUsers({ app_user_id: 42 }).userIds, []);
});

Deno.test("evento ausente o que no es objeto: vacío", () => {
  assertEquals(resolveEventUsers(undefined).userIds, []);
  assertEquals(resolveEventUsers(null).userIds, []);
  assertEquals(resolveEventUsers("TRANSFER").userIds, []);
});

Deno.test("más de 20 usuarios: se recorta y se avisa", () => {
  const many = Array.from({ length: MAX_EVENT_USERS + 5 }, (_, i) => `u${i}`);
  const result = resolveEventUsers({ transferred_to: many });
  assertEquals(result.userIds.length, MAX_EVENT_USERS);
  assertEquals(result.truncated, true);
});

Deno.test("exactamente el tope: no se considera recortado", () => {
  const exact = Array.from({ length: MAX_EVENT_USERS }, (_, i) => `u${i}`);
  const result = resolveEventUsers({ transferred_to: exact });
  assertEquals(result.userIds.length, MAX_EVENT_USERS);
  assertEquals(result.truncated, false);
});
