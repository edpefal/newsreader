import { assertEquals } from "jsr:@std/assert@1";
import { verifySvixSignature } from "./verify_signature.ts";

// Vector de ejemplo de la documentación de Svix
// (docs.svix.com/receiving/verifying-payloads/how-manual).
const secret = "whsec_MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw";
const svixId = "msg_p5jXN8AQM9LWM0D4loKWxJek";
const svixTimestamp = "1614265330";
const rawBody = '{"test": 2432232314}';
const validSignature = "v1,g0hM9SsE+OTPJTGt/tmIKtSyZlE3uFJELVlNIOLJ1OE=";

Deno.test("firma válida se acepta", async () => {
  const isValid = await verifySvixSignature({
    secret,
    svixId,
    svixTimestamp,
    rawBody,
    svixSignatureHeader: validSignature,
  });
  assertEquals(isValid, true);
});

Deno.test("firma inválida se rechaza", async () => {
  const isValid = await verifySvixSignature({
    secret,
    svixId,
    svixTimestamp,
    rawBody,
    svixSignatureHeader: "v1,firmaquenocoincideparanada==",
  });
  assertEquals(isValid, false);
});

Deno.test("body alterado invalida la firma original", async () => {
  const isValid = await verifySvixSignature({
    secret,
    svixId,
    svixTimestamp,
    rawBody: '{"test": 999}',
    svixSignatureHeader: validSignature,
  });
  assertEquals(isValid, false);
});

Deno.test("headers svix faltantes se rechazan", async () => {
  const isValid = await verifySvixSignature({
    secret,
    svixId: null,
    svixTimestamp,
    rawBody,
    svixSignatureHeader: validSignature,
  });
  assertEquals(isValid, false);
});

Deno.test("acepta la firma correcta entre varias (rotación de secret)", async () => {
  const isValid = await verifySvixSignature({
    secret,
    svixId,
    svixTimestamp,
    rawBody,
    svixSignatureHeader: `v1,firmavieja== ${validSignature}`,
  });
  assertEquals(isValid, true);
});
