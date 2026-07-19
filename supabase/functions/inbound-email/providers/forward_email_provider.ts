// Implementación de EmailProvider para ForwardEmail.net.
// Ver openspec/changes/email-to-rss-generated-feeds/design.md Decisión 5.
import type {
  EmailProvider,
  NormalizedInboundEmail,
} from "./email_provider.ts";

const FORWARDEMAIL_IPS_URL = "https://forwardemail.net/ips.json";
const IP_CACHE_TTL_MS = 60 * 60 * 1000; // 1 hora

interface ForwardEmailPayload {
  recipients?: string[];
  from?: { value?: Array<{ address?: string; name?: string }>; text?: string };
  subject?: string;
  text?: string;
  html?: string;
  date?: string;
  messageId?: string;
}

/** Decodificador simple de encoded-words RFC 2047 (=?UTF-8?B?...?= / ?Q?...?=). */
function decodeEncodedWords(text: string): string {
  if (!text) return text;
  return text.replace(
    /=\?([^?]+)\?([BQ])\?([^?]+)\?=/gi,
    (_match, _charset, encoding, encoded) => {
      if (encoding.toUpperCase() === "B") {
        try {
          return atob(encoded);
        } catch {
          return encoded;
        }
      }
      return encoded
        .replace(/_/g, " ")
        .replace(/=([0-9A-F]{2})/gi, (_m: string, hex: string) =>
          String.fromCharCode(parseInt(hex, 16)));
    },
  );
}

export class ForwardEmailProvider implements EmailProvider {
  // ForwardEmail no ofrece firma HMAC verificable para este tipo de webhook
  // (investigado explícitamente). La autenticación es de doble capa: secreto
  // compartido en la query string + allowlist de IP contra la lista
  // publicada y mantenida por ForwardEmail (cacheada, ya que puede cambiar).
  private cachedIps: { addresses: Set<string>; fetchedAt: number } | null =
    null;

  async verifyRequest(req: Request): Promise<boolean> {
    const url = new URL(req.url);
    const secret = url.searchParams.get("secret");
    const expectedSecret = Deno.env.get("FORWARDEMAIL_WEBHOOK_SECRET");

    if (!expectedSecret || secret !== expectedSecret) {
      return false;
    }

    const clientIp = this.clientIpFrom(req);
    const allowedIps = await this.getAllowedIps();
    if (!clientIp || !allowedIps.has(clientIp)) {
      console.warn(`Rechazado: IP de origen no permitida (${clientIp})`);
      return false;
    }

    return true;
  }

  parsePayload(json: unknown): NormalizedInboundEmail {
    const payload = json as ForwardEmailPayload;

    const toAddress = payload.recipients?.[0] ?? "";
    const subject = decodeEncodedWords(payload.subject ?? "Sin asunto");
    const contentHtml = payload.html || payload.text || "";
    const fromAddress = payload.from?.value?.[0]?.address ||
      payload.from?.text ||
      null;
    const receivedAt = payload.date ? new Date(payload.date) : new Date();
    const messageId = payload.messageId ?? crypto.randomUUID();

    return { toAddress, subject, contentHtml, fromAddress, receivedAt, messageId };
  }

  private clientIpFrom(req: Request): string | null {
    const forwardedFor = req.headers.get("x-forwarded-for");
    if (!forwardedFor) return null;
    return forwardedFor.split(",")[0]?.trim() || null;
  }

  private async getAllowedIps(): Promise<Set<string>> {
    if (
      this.cachedIps &&
      Date.now() - this.cachedIps.fetchedAt < IP_CACHE_TTL_MS
    ) {
      return this.cachedIps.addresses;
    }

    const response = await fetch(FORWARDEMAIL_IPS_URL);
    const entries = await response.json() as Array<
      { ipv4?: string[]; ipv6?: string[] }
    >;

    const addresses = new Set<string>();
    for (const entry of entries) {
      for (const ip of entry.ipv4 ?? []) addresses.add(ip);
      for (const ip of entry.ipv6 ?? []) addresses.add(ip);
    }

    this.cachedIps = { addresses, fetchedAt: Date.now() };
    return addresses;
  }
}
