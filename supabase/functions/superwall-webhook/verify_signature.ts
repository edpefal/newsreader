// Verificación manual de la firma Svix (el proveedor de webhooks que usa
// Superwall) sin depender de la librería `svix`, siguiendo el algoritmo
// documentado en docs.svix.com/receiving/verifying-payloads/how-manual:
// HMAC-SHA256 sobre "{svix-id}.{svix-timestamp}.{raw-body}", con el secret
// decodificado en base64 después de sacarle el prefijo "whsec_". El header
// `svix-signature` puede traer varias firmas separadas por espacio (una
// por versión de secret activa), cada una con el formato "v1,<firma>".

function base64ToBytes(base64: string): Uint8Array {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

// Comparación en tiempo constante para no filtrar información por timing.
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

export interface VerifySvixSignatureParams {
  secret: string;
  svixId: string | null;
  svixTimestamp: string | null;
  rawBody: string;
  svixSignatureHeader: string | null;
}

export async function verifySvixSignature(
  { secret, svixId, svixTimestamp, rawBody, svixSignatureHeader }:
    VerifySvixSignatureParams,
): Promise<boolean> {
  if (!svixId || !svixTimestamp || !svixSignatureHeader) return false;

  const secretKey = secret.startsWith("whsec_") ? secret.slice(6) : secret;
  const keyBytes = base64ToBytes(secretKey);
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    keyBytes.buffer as ArrayBuffer,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signedContent = `${svixId}.${svixTimestamp}.${rawBody}`;
  const signatureBytes = await crypto.subtle.sign(
    "HMAC",
    cryptoKey,
    new TextEncoder().encode(signedContent).buffer as ArrayBuffer,
  );
  const expectedSignature = bytesToBase64(new Uint8Array(signatureBytes));

  const receivedSignatures = svixSignatureHeader
    .split(" ")
    .map((part) => part.split(",")[1])
    .filter((sig): sig is string => Boolean(sig));

  return receivedSignatures.some((sig) =>
    timingSafeEqual(sig, expectedSignature)
  );
}
