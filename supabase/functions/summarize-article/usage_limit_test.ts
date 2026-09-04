import { assertEquals } from "jsr:@std/assert@1";
import {
  AI_DAILY_SUMMARY_LIMIT,
  AI_FREE_TIER_DAILY_LIMIT,
  resolveDailyLimit,
} from "./usage_limit.ts";

Deno.test("con suscripción activa, límite de 25", () => {
  assertEquals(resolveDailyLimit(true), AI_DAILY_SUMMARY_LIMIT);
});

Deno.test("sin suscripción activa, límite de 2", () => {
  assertEquals(resolveDailyLimit(false), AI_FREE_TIER_DAILY_LIMIT);
});
