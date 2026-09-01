import { assertEquals } from "jsr:@std/assert@1";
import { todayUtcRange } from "./today_range.ts";

Deno.test("da el inicio y fin del día UTC en curso", () => {
  const { start, end } = todayUtcRange(new Date("2026-08-31T15:42:07.123Z"));
  assertEquals(start.toISOString(), "2026-08-31T00:00:00.000Z");
  assertEquals(end.toISOString(), "2026-09-01T00:00:00.000Z");
});

Deno.test("un instante justo antes de medianoche UTC queda en el día anterior", () => {
  const { start, end } = todayUtcRange(new Date("2026-08-31T23:59:59.999Z"));
  assertEquals(start.toISOString(), "2026-08-31T00:00:00.000Z");
  assertEquals(end.toISOString(), "2026-09-01T00:00:00.000Z");
});

Deno.test("un instante justo en medianoche UTC ya es el día siguiente", () => {
  const { start, end } = todayUtcRange(new Date("2026-09-01T00:00:00.000Z"));
  assertEquals(start.toISOString(), "2026-09-01T00:00:00.000Z");
  assertEquals(end.toISOString(), "2026-09-02T00:00:00.000Z");
});

Deno.test("cruza correctamente el límite de fin de mes/año", () => {
  const { start, end } = todayUtcRange(new Date("2025-12-31T10:00:00.000Z"));
  assertEquals(start.toISOString(), "2025-12-31T00:00:00.000Z");
  assertEquals(end.toISOString(), "2026-01-01T00:00:00.000Z");
});
