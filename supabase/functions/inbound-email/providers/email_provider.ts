// Abstracción del proveedor de email entrante. Permite reemplazar
// ForwardEmail.net (o sumar otro proveedor, o un servidor SMTP propio en el
// futuro) sin tocar la lógica de negocio en index.ts.

/** Un email entrante ya normalizado, sin importar de qué proveedor vino. */
export interface NormalizedInboundEmail {
  /** Dirección completa de destino (ej. "abc-123@inbox.image2svg.app"). */
  toAddress: string;
  subject: string;
  /** Contenido HTML del correo (o texto plano si no había HTML). */
  contentHtml: string;
  fromAddress: string | null;
  receivedAt: Date;
  /** Identificador único del mensaje, para deduplicar reintentos de entrega. */
  messageId: string;
}

export interface EmailProvider {
  /**
   * Valida que el request realmente venga del proveedor configurado
   * (secreto, IP allowlist, firma, etc. según lo que soporte cada uno).
   */
  verifyRequest(req: Request): Promise<boolean>;

  /** Convierte el payload crudo del proveedor a nuestro formato interno. */
  parsePayload(json: unknown): NormalizedInboundEmail;
}
