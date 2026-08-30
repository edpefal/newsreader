// Resolución de una mención cruda contra el proveedor externo que le
// corresponde por tipo: Google Books para libros, iTunes Search para
// podcasts/música, y un fetch de Open Graph a la URL detectada para
// artículos citados (ver add-article-mentioned-links/design.md). Ninguno
// requiere una API key secreta -- ver design.md de
// add-article-summary-mentions sobre por qué igual se proxea desde el
// backend en vez de llamarse directo desde la app.
//
// `fetchImpl` se inyecta para poder testear sin red real (mismo patrón que
// el resto de las funciones testeables de esta carpeta).
import type { EnrichedMention, RawMention } from "./mention_types.ts";
import { isSafePublicUrl } from "./url_safety.ts";

export type FetchLike = typeof fetch;

const GOOGLE_BOOKS_URL = "https://www.googleapis.com/books/v1/volumes";
const ITUNES_SEARCH_URL = "https://itunes.apple.com/search";

/// Link de búsqueda de Amazon para una mención de libro. Se construye
/// siempre a partir del nombre, sin depender de ningún proveedor externo
/// -- ver design.md de add-book-mention-amazon-link sobre por qué se
/// prefiere esto a la Product Advertising API. `i=stripbooks` acota la
/// búsqueda a libros físicos, evitando que el primer resultado sea un
/// Kindle/audiolibro o un producto no relacionado.
function buildAmazonSearchLink(name: string): string {
  return `https://www.amazon.com/s?k=${encodeURIComponent(name)}&i=stripbooks`;
}

// Timeout corto para el fetch de Open Graph -- una página citada que no
// responde no debería demorar la generación del resumen. Un timeout se
// trata igual que cualquier otra falla de fetch (mención sin enriquecer,
// con el link original igual).
const OG_FETCH_TIMEOUT_MS = 8000;

/// Resuelve solo la portada de un libro contra Google Books, best-effort.
/// El `link` de una mención de libro NO sale de acá -- ver
/// `buildAmazonSearchLink` y `enrichMention`.
async function resolveBookCover(
  name: string,
  fetchImpl: FetchLike,
): Promise<string | undefined> {
  const url = `${GOOGLE_BOOKS_URL}?q=${encodeURIComponent(name)}&maxResults=1`;
  const response = await fetchImpl(url);
  if (!response.ok) return undefined;
  const data = await response.json();
  const item = data?.items?.[0];
  const volumeInfo = item?.volumeInfo;
  return volumeInfo?.imageLinks?.thumbnail;
}

async function resolveAudio(
  name: string,
  entity: "podcast" | "musicTrack",
  fetchImpl: FetchLike,
): Promise<{ imageUrl?: string; link?: string } | null> {
  const url = `${ITUNES_SEARCH_URL}?term=${
    encodeURIComponent(name)
  }&entity=${entity}&limit=1`;
  const response = await fetchImpl(url);
  if (!response.ok) return null;
  const data = await response.json();
  const result = data?.results?.[0];
  if (!result) return null;
  return {
    imageUrl: result.artworkUrl100,
    link: result.trackViewUrl ?? result.collectionViewUrl,
  };
}

function extractMetaContent(html: string, property: string): string | undefined {
  const escaped = property.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const patterns = [
    new RegExp(
      `<meta[^>]+property=["']${escaped}["'][^>]*content=["']([^"']*)["']`,
      "i",
    ),
    new RegExp(
      `<meta[^>]+content=["']([^"']*)["'][^>]*property=["']${escaped}["']`,
      "i",
    ),
  ];
  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match) return match[1];
  }
  return undefined;
}

function extractTitleTag(html: string): string | undefined {
  const match = html.match(/<title[^>]*>([^<]*)<\/title>/i);
  return match?.[1]?.trim() || undefined;
}

/// Fetchea [url] (ya validada como pública/segura por el caller) y extrae
/// su título e imagen de Open Graph, con fallback a `<title>` si falta
/// `og:title`. Devuelve `null` si la request falla, tarda más que
/// [OG_FETCH_TIMEOUT_MS], o no encuentra ni título ni imagen.
async function resolveArticle(
  url: string,
  fetchImpl: FetchLike,
): Promise<{ imageUrl?: string; title?: string } | null> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), OG_FETCH_TIMEOUT_MS);
  try {
    const response = await fetchImpl(url, { signal: controller.signal });
    if (!response.ok) return null;
    const html = await response.text();
    const title = extractMetaContent(html, "og:title") ?? extractTitleTag(html);
    const imageUrl = extractMetaContent(html, "og:image");
    if (!title && !imageUrl) return null;
    return { imageUrl, title };
  } finally {
    clearTimeout(timeoutId);
  }
}

/// Resuelve una mención contra su proveedor. Para `podcast`/`music`, si el
/// proveedor no encuentra match o la request falla, devuelve la mención sin
/// `imageUrl`/`link` (nunca `null` ni la descarta) -- ver capability
/// article-mentions, requirement "Mención de podcast o música sin match del
/// proveedor se muestra igual". Para `book`, en cambio, `link` SHALL setearse
/// siempre a un link de búsqueda de Amazon (ver `buildAmazonSearchLink`),
/// independientemente de si Google Books encuentra la portada -- ver
/// requirement "Mención de libro siempre tiene link, con o sin match en
/// Google Books".
///
/// Para `type: "article"`, `link` SHALL setearse siempre a la URL original
/// detectada (haya o no éxito el fetch de Open Graph, e incluso si la URL
/// fue rechazada por `isSafePublicUrl`) -- a diferencia de libro/podcast/
/// música, esta URL no viene de una búsqueda por nombre sino que ya se
/// extrajo directamente del artículo, así que siempre hay un link real
/// para mostrar.
export async function enrichMention(
  mention: RawMention,
  fetchImpl: FetchLike = fetch,
): Promise<EnrichedMention> {
  if (mention.type === "article") {
    const url = mention.url!;
    if (!isSafePublicUrl(url)) {
      return { ...mention, link: url };
    }
    try {
      const result = await resolveArticle(url, fetchImpl);
      return {
        ...mention,
        name: result?.title ?? mention.name,
        imageUrl: result?.imageUrl,
        link: url,
      };
    } catch (e) {
      console.error(`enrichMention (article) failed for "${url}": ${e}`);
      return { ...mention, link: url };
    }
  }

  if (mention.type === "book") {
    let imageUrl: string | undefined;
    try {
      imageUrl = await resolveBookCover(mention.name, fetchImpl);
    } catch (e) {
      console.error(`enrichMention (book) failed for "${mention.name}": ${e}`);
    }
    return { ...mention, imageUrl, link: buildAmazonSearchLink(mention.name) };
  }

  try {
    const result = await resolveAudio(
      mention.name,
      mention.type === "podcast" ? "podcast" : "musicTrack",
      fetchImpl,
    );
    return { ...mention, imageUrl: result?.imageUrl, link: result?.link };
  } catch (e) {
    console.error(`enrichMention failed for "${mention.name}": ${e}`);
    return { ...mention };
  }
}
