// Selección del contenido de un artículo para el resumen diario: texto
// completo de `content_html` cuando no está truncado, `excerpt` como
// fallback en caso contrario -- mismo criterio que
// `FeedContentChecker.isTruncated`/`HtmlToPlainText` del cliente (ver
// capability `daily-summaries`), reimplementado acá porque el cliente ya no
// arma esta solicitud: ahora la genera este proceso del servidor
// directamente desde Postgres.

// Mismo valor que `AppConstants.articleTruncatedThreshold` en el cliente.
const ARTICLE_TRUNCATED_THRESHOLD = 500;

export interface ArticleContentSource {
  content_html: string | null;
  excerpt: string | null;
}

/** Mismo criterio que `FeedContentChecker.isTruncated` del cliente Flutter. */
export function isTruncated(contentHtml: string | null | undefined): boolean {
  if (!contentHtml || contentHtml.trim().length === 0) return true;
  return contentHtml.length < ARTICLE_TRUNCATED_THRESHOLD;
}

const SCRIPT_OR_STYLE_BLOCK = /<(script|style)\b[^>]*>[\s\S]*?<\/\1>/gi;
const BLOCK_TAG_END =
  /<(br\s*\/?|\/p|\/div|\/tr|\/li|\/h[1-6]|\/table|\/section|\/article)\s*>/gi;
const ANY_TAG = /<[^>]*>/g;
const NUMERIC_ENTITY = /&#(\d+);/g;
const TRAILING_SPACES = /[ \t]+\n/g;
const REPEATED_SPACES = /[ \t]{2,}/g;
const BLANK_LINES = /\n[ \t]*\n[ \t]*(\n[ \t]*)*/g;

const NAMED_ENTITIES: ReadonlyArray<[string, string]> = [
  ["&amp;", "&"],
  ["&nbsp;", " "],
  ["&lt;", "<"],
  ["&gt;", ">"],
  ["&quot;", '"'],
  ["&#39;", "'"],
  ["&apos;", "'"],
];

/** Mismo criterio que `HtmlToPlainText.convert` del cliente Flutter. */
export function htmlToPlainText(html: string): string {
  let text = html.replace(SCRIPT_OR_STYLE_BLOCK, "");
  text = text.replace(BLOCK_TAG_END, "\n");
  text = text.replace(ANY_TAG, "");

  for (const [entity, value] of NAMED_ENTITIES) {
    text = text.split(entity).join(value);
  }
  text = text.replace(NUMERIC_ENTITY, (_match, codeStr: string) => {
    const codePoint = parseInt(codeStr, 10);
    if (Number.isNaN(codePoint) || codePoint < 0 || codePoint > 0x10ffff) {
      return "";
    }
    // Surrogates aislados no son un scalar value válido por sí solos.
    if (codePoint >= 0xd800 && codePoint <= 0xdfff) return "";
    return String.fromCodePoint(codePoint);
  });

  text = text.replace(TRAILING_SPACES, "\n");
  text = text.replace(REPEATED_SPACES, " ");
  text = text.replace(BLANK_LINES, "\n\n");

  return text.trim();
}

/**
 * Texto plano completo de `content_html` cuando el artículo no está
 * truncado; `excerpt` (o cadena vacía) como fallback en caso contrario.
 */
export function articleContentFor(article: ArticleContentSource): string {
  if (!isTruncated(article.content_html)) {
    return htmlToPlainText(article.content_html!);
  }
  return article.excerpt ?? "";
}
