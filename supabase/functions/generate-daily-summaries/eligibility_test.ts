import { assertEquals } from "jsr:@std/assert@1";
import {
  isEligibleToday,
  isMondayLocal,
  isPastGenerationThreshold,
} from "./eligibility.ts";

// 2026-08-31 es lunes; 2026-09-01 es martes.

Deno.test("isPastGenerationThreshold: hora local ya pasó el umbral", () => {
  // 08:00 UTC, offset 0 => 08:00 local, umbral 06:00.
  assertEquals(
    isPastGenerationThreshold(new Date("2026-08-31T08:00:00Z"), 0, 6),
    true,
  );
});

Deno.test("isPastGenerationThreshold: hora local todavía no alcanza el umbral", () => {
  assertEquals(
    isPastGenerationThreshold(new Date("2026-08-31T04:00:00Z"), 0, 6),
    false,
  );
});

Deno.test("isPastGenerationThreshold: exactamente en el umbral cuenta como pasado", () => {
  assertEquals(
    isPastGenerationThreshold(new Date("2026-08-31T06:00:00Z"), 0, 6),
    true,
  );
});

Deno.test("isPastGenerationThreshold: offset negativo corre la hora local hacia atrás", () => {
  // 08:00 UTC en offset -180 (UTC-3) es 05:00 local, todavía no llega a las 06:00.
  assertEquals(
    isPastGenerationThreshold(new Date("2026-08-31T08:00:00Z"), -180, 6),
    false,
  );
});

Deno.test("isPastGenerationThreshold: offset positivo adelanta la hora local", () => {
  // 22:00 UTC en offset +540 (UTC+9) es 07:00 del día siguiente localmente.
  assertEquals(
    isPastGenerationThreshold(new Date("2026-08-31T22:00:00Z"), 540, 6),
    true,
  );
});

Deno.test("isMondayLocal: true cuando la fecha local cae en lunes", () => {
  assertEquals(isMondayLocal(new Date("2026-08-31T12:00:00Z"), 0), true);
});

Deno.test("isMondayLocal: false cuando la fecha local no es lunes", () => {
  assertEquals(isMondayLocal(new Date("2026-09-01T12:00:00Z"), 0), false);
});

Deno.test("isMondayLocal: el offset puede correr la fecha local a lunes aunque UTC no lo sea", () => {
  // 2026-09-01T01:00Z (martes en UTC) con offset -180 (UTC-3) es
  // 2026-08-31T22:00 local (lunes).
  assertEquals(isMondayLocal(new Date("2026-09-01T01:00:00Z"), -180), true);
});

Deno.test("isMondayLocal: el offset puede correr la fecha local fuera de lunes aunque UTC sí lo sea", () => {
  // 2026-08-31T23:00Z (lunes en UTC) con offset +180 es 2026-09-01T02:00
  // local (martes).
  assertEquals(isMondayLocal(new Date("2026-08-31T23:00:00Z"), 180), false);
});

Deno.test("isEligibleToday: suscripción activa es elegible cualquier día", () => {
  assertEquals(isEligibleToday(true, false), true);
  assertEquals(isEligibleToday(true, true), true);
});

Deno.test("isEligibleToday: sin suscripción, elegible solo si hoy es lunes", () => {
  assertEquals(isEligibleToday(false, true), true);
  assertEquals(isEligibleToday(false, false), false);
});
