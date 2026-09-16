import { assertEquals } from "jsr:@std/assert@1";
import { hasSummaryForToday, resolveUtcOffsetMinutes } from "./user_context.ts";

Deno.test("resolveUtcOffsetMinutes: usa el offset persistido cuando hay fila", () => {
  assertEquals(
    resolveUtcOffsetMinutes({ locale: "es", utc_offset_minutes: -180 }),
    -180,
  );
});

Deno.test("resolveUtcOffsetMinutes: cae a UTC+0 sin fila de preferencias", () => {
  assertEquals(resolveUtcOffsetMinutes(null), 0);
});

Deno.test("resolveUtcOffsetMinutes: cae a UTC+0 si el offset persistido es null", () => {
  assertEquals(
    resolveUtcOffsetMinutes({ locale: "es", utc_offset_minutes: null }),
    0,
  );
});

Deno.test("hasSummaryForToday: true si ya existe un DailySummary de hoy", () => {
  assertEquals(hasSummaryForToday({ id: "user-1-2026-08-31" }), true);
});

Deno.test("hasSummaryForToday: false sin DailySummary de hoy (idempotencia permite generar)", () => {
  assertEquals(hasSummaryForToday(null), false);
});
