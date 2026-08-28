// Resolución de una mención cruda contra el proveedor externo que le
// corresponde por tipo: Google Books para libros, iTunes Search para
// podcasts/música. Ninguno de los dos requiere una API key secreta -- ver
// design.md de add-article-summary-mentions sobre por qué igual se
// proxea desde el backend en vez de llamarse directo desde la app.
//
// `fetchImpl` se inyecta para poder testear sin red real (mismo patrón que
// el resto de las funciones testeables de esta carpeta).
import type { EnrichedMention, RawMention } from "./mention_types.ts";

export type FetchLike = typeof fetch;

const GOOGLE_BOOKS_URL = "https://www.googleapis.com/books/v1/volumes";
const ITUNES_SEARCH_URL = "https://itunes.apple.com/search";

async function resolveBook(
  name: string,
  fetchImpl: FetchLike,
): Promise<{ imageUrl?: string; link?: string } | null> {
  const url = `${GOOGLE_BOOKS_URL}?q=${encodeURIComponent(name)}&maxResults=1`;
  const response = await fetchImpl(url);
  if (!response.ok) return null;
  const data = await response.json();
  const item = data?.items?.[0];
  const volumeInfo = item?.volumeInfo;
  if (!volumeInfo) return null;
  return {
    imageUrl: volumeInfo.imageLinks?.thumbnail,
    link: volumeInfo.infoLink ?? volumeInfo.previewLink,
  };
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

/// Resuelve una mención contra su proveedor. Si el proveedor no encuentra
/// match, o la request falla, devuelve la mención sin `imageUrl`/`link`
/// (nunca `null` ni la descarta) -- ver capability article-mentions,
/// requirement "Mención sin match del proveedor se muestra igual".
export async function enrichMention(
  mention: RawMention,
  fetchImpl: FetchLike = fetch,
): Promise<EnrichedMention> {
  try {
    const result = mention.type === "book"
      ? await resolveBook(mention.name, fetchImpl)
      : await resolveAudio(
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
