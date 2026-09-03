// Chequeo de seguridad extraído a una función pura y testeable (mismo
// patrón que el resto de esta carpeta). `enrich-mentions` es la primera
// función que hace fetch a una URL arbitraria provista indirectamente por
// contenido externo (un artículo de un feed RSS de un tercero) -- sin este
// chequeo, un feed malicioso podría citar una URL interna de la
// infraestructura (ej. un endpoint de metadata de la nube) y usar el
// backend como proxy para alcanzarla (SSRF).
//
// Esto es un chequeo estático sobre el literal de la URL (esquema +
// hostname), no una resolución DNS real: no protege contra DNS rebinding
// (un dominio público que resuelve a una IP privada). Se acepta ese límite
// por ahora -- resolver DNS desde una Edge Function agrega permisos y
// complejidad que no se justifican para este caso (metadata de Open Graph
// de una URL citada en texto, no un endpoint de alto valor).
const PRIVATE_IPV4_PATTERNS = [
  /^127\./,
  /^10\./,
  /^172\.(1[6-9]|2\d|3[01])\./,
  /^192\.168\./,
  /^169\.254\./,
  /^0\./,
];

function isPrivateIPv4(hostname: string): boolean {
  return PRIVATE_IPV4_PATTERNS.some((pattern) => pattern.test(hostname));
}

function isLoopbackOrLinkLocalIPv6(hostname: string): boolean {
  const host = hostname.toLowerCase();
  return host === "::1" || host === "[::1]" ||
    host.startsWith("fe80:") || host.startsWith("[fe80:") ||
    host.startsWith("fc") || host.startsWith("[fc") ||
    host.startsWith("fd") || host.startsWith("[fd");
}

export function isSafePublicUrl(rawUrl: string): boolean {
  let url: URL;
  try {
    url = new URL(rawUrl);
  } catch {
    return false;
  }

  if (url.protocol !== "http:" && url.protocol !== "https:") return false;

  const hostname = url.hostname.toLowerCase();
  if (hostname === "localhost" || hostname === "") return false;
  if (isPrivateIPv4(hostname)) return false;
  if (isLoopbackOrLinkLocalIPv6(hostname)) return false;

  return true;
}
