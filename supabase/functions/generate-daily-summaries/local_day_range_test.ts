import { assertEquals } from "jsr:@std/assert@1";
import { localDayRange, todayUtcRange } from "./local_day_range.ts";

Deno.test("offset 0: da el inicio y fin del día UTC en curso", () => {
  const { start, end } = todayUtcRange(new Date("2026-08-31T15:42:07.123Z"));
  assertEquals(start.toISOString(), "2026-08-31T00:00:00.000Z");
  assertEquals(end.toISOString(), "2026-09-01T00:00:00.000Z");
});

Deno.test("offset 0: un instante justo antes de medianoche UTC queda en el día anterior", () => {
  const { start, end } = todayUtcRange(new Date("2026-08-31T23:59:59.999Z"));
  assertEquals(start.toISOString(), "2026-08-31T00:00:00.000Z");
  assertEquals(end.toISOString(), "2026-09-01T00:00:00.000Z");
});

Deno.test("offset 0: cruza correctamente el límite de fin de mes/año", () => {
  const { start, end } = localDayRange(new Date("2025-12-31T10:00:00.000Z"), 0);
  assertEquals(start.toISOString(), "2025-12-31T00:00:00.000Z");
  assertEquals(end.toISOString(), "2026-01-01T00:00:00.000Z");
});

Deno.test("offset negativo (UTC-3, ej. Argentina): un instante de madrugada UTC todavía es el día anterior localmente", () => {
  // 02:00 UTC del 1 de septiembre es 23:00 del 31 de agosto en UTC-3.
  const { start, end } = localDayRange(
    new Date("2026-09-01T02:00:00.000Z"),
    -180,
  );
  assertEquals(start.toISOString(), "2026-08-31T03:00:00.000Z");
  assertEquals(end.toISOString(), "2026-09-01T03:00:00.000Z");
});

Deno.test("offset positivo (UTC+9, ej. Japón): un instante de la tarde UTC ya es el día siguiente localmente", () => {
  // 16:00 UTC del 31 de agosto es 01:00 del 1 de septiembre en UTC+9.
  const { start, end } = localDayRange(
    new Date("2026-08-31T16:00:00.000Z"),
    540,
  );
  assertEquals(start.toISOString(), "2026-08-31T15:00:00.000Z");
  assertEquals(end.toISOString(), "2026-09-01T15:00:00.000Z");
});

Deno.test("offset positivo: justo en el instante de cambio de día local", () => {
  const { start, end } = localDayRange(
    new Date("2026-08-31T15:00:00.000Z"),
    540,
  );
  assertEquals(start.toISOString(), "2026-08-31T15:00:00.000Z");
  assertEquals(end.toISOString(), "2026-09-01T15:00:00.000Z");
});
