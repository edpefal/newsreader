import { assertEquals } from "jsr:@std/assert@1";
import { isSafePublicUrl } from "./url_safety.ts";

Deno.test("acepta una URL https pública normal", () => {
  assertEquals(isSafePublicUrl("https://example.com/article"), true);
});

Deno.test("acepta una URL http pública normal", () => {
  assertEquals(isSafePublicUrl("http://example.com/article"), true);
});

Deno.test("rechaza un esquema distinto de http/https", () => {
  assertEquals(isSafePublicUrl("ftp://example.com/file"), false);
  assertEquals(isSafePublicUrl("file:///etc/passwd"), false);
  assertEquals(isSafePublicUrl("javascript:alert(1)"), false);
});

Deno.test("rechaza una URL malformada", () => {
  assertEquals(isSafePublicUrl("no es una url"), false);
  assertEquals(isSafePublicUrl(""), false);
});

Deno.test("rechaza localhost", () => {
  assertEquals(isSafePublicUrl("http://localhost:8080/"), false);
});

Deno.test("rechaza IPv4 loopback y rangos privados", () => {
  assertEquals(isSafePublicUrl("http://127.0.0.1/"), false);
  assertEquals(isSafePublicUrl("http://10.0.0.5/"), false);
  assertEquals(isSafePublicUrl("http://172.16.0.1/"), false);
  assertEquals(isSafePublicUrl("http://172.31.255.255/"), false);
  assertEquals(isSafePublicUrl("http://192.168.1.1/"), false);
  assertEquals(isSafePublicUrl("http://169.254.169.254/"), false);
});

Deno.test("acepta un rango 172.x fuera del bloque privado (172.32.x)", () => {
  assertEquals(isSafePublicUrl("http://172.32.0.1/"), true);
});

Deno.test("rechaza IPv6 loopback y link-local", () => {
  assertEquals(isSafePublicUrl("http://[::1]/"), false);
  assertEquals(isSafePublicUrl("http://[fe80::1]/"), false);
});
