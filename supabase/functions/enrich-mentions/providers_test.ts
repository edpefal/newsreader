import { assertEquals } from "jsr:@std/assert@1";
import { enrichMention, type FetchLike } from "./providers.ts";

function fakeFetch(body: unknown, ok = true): FetchLike {
  return (() =>
    Promise.resolve(
      new Response(JSON.stringify(body), { status: ok ? 200 : 500 }),
    )) as unknown as FetchLike;
}

function fakeHtmlFetch(html: string, ok = true): FetchLike {
  return (() =>
    Promise.resolve(
      new Response(html, {
        status: ok ? 200 : 500,
        headers: { "Content-Type": "text/html" },
      }),
    )) as unknown as FetchLike;
}

Deno.test("enriquece un libro con match en Google Books", async () => {
  const fetchImpl = fakeFetch({
    items: [{
      volumeInfo: {
        imageLinks: { thumbnail: "https://books.example/cover.jpg" },
        infoLink: "https://books.example/info",
      },
    }],
  });
  const result = await enrichMention(
    { type: "book", name: "Project Hail Mary" },
    fetchImpl,
  );
  assertEquals(result, {
    type: "book",
    name: "Project Hail Mary",
    imageUrl: "https://books.example/cover.jpg",
    link: "https://books.example/info",
  });
});

Deno.test("enriquece un podcast con match en iTunes Search", async () => {
  const fetchImpl = fakeFetch({
    results: [{
      artworkUrl100: "https://itunes.example/art.jpg",
      trackViewUrl: "https://itunes.example/podcast",
    }],
  });
  const result = await enrichMention(
    { type: "podcast", name: "Radiolab" },
    fetchImpl,
  );
  assertEquals(result, {
    type: "podcast",
    name: "Radiolab",
    imageUrl: "https://itunes.example/art.jpg",
    link: "https://itunes.example/podcast",
  });
});

Deno.test("mención sin match se devuelve sin imageUrl ni link", async () => {
  const fetchImpl = fakeFetch({ items: [] });
  const result = await enrichMention(
    { type: "book", name: "Un libro inexistente" },
    fetchImpl,
  );
  assertEquals(result, {
    type: "book",
    name: "Un libro inexistente",
    imageUrl: undefined,
    link: undefined,
  });
});

Deno.test("falla del proveedor se trata igual que sin match", async () => {
  const fetchImpl = fakeFetch({}, false);
  const result = await enrichMention(
    { type: "music", name: "Random Access Memories" },
    fetchImpl,
  );
  assertEquals(result, {
    type: "music",
    name: "Random Access Memories",
    imageUrl: undefined,
    link: undefined,
  });
});

Deno.test("una excepción de red se trata igual que sin match", async () => {
  const throwingFetch: FetchLike =
    (() => Promise.reject(new Error("network down"))) as unknown as FetchLike;
  const result = await enrichMention(
    { type: "podcast", name: "Algo" },
    throwingFetch,
  );
  assertEquals(result, { type: "podcast", name: "Algo" });
});

Deno.test("enriquece un artículo con og:title y og:image", async () => {
  const fetchImpl = fakeHtmlFetch(
    '<html><head>' +
      '<meta property="og:title" content="Un título real">' +
      '<meta property="og:image" content="https://cdn.example/cover.jpg">' +
      '</head></html>',
  );
  const result = await enrichMention(
    {
      type: "article",
      name: "nombre inferido por Gemini",
      url: "https://other.example.com/post",
    },
    fetchImpl,
  );
  assertEquals(result, {
    type: "article",
    name: "Un título real",
    url: "https://other.example.com/post",
    imageUrl: "https://cdn.example/cover.jpg",
    link: "https://other.example.com/post",
  });
});

Deno.test("artículo sin og:title cae a <title> como fallback", async () => {
  const fetchImpl = fakeHtmlFetch(
    "<html><head><title>Título del tag title</title></head></html>",
  );
  const result = await enrichMention(
    { type: "article", name: "nombre inferido", url: "https://other.example.com/post" },
    fetchImpl,
  );
  assertEquals(result.name, "Título del tag title");
  assertEquals(result.link, "https://other.example.com/post");
});

Deno.test("artículo cuyo fetch de Open Graph falla igual queda con link", async () => {
  const fetchImpl = fakeHtmlFetch("", false);
  const result = await enrichMention(
    { type: "article", name: "nombre inferido", url: "https://other.example.com/post" },
    fetchImpl,
  );
  assertEquals(result, {
    type: "article",
    name: "nombre inferido",
    url: "https://other.example.com/post",
    link: "https://other.example.com/post",
    imageUrl: undefined,
  });
});

Deno.test("artículo sin ningún metadato igual queda con link", async () => {
  const fetchImpl = fakeHtmlFetch("<html><head></head><body>sin metadata</body></html>");
  const result = await enrichMention(
    { type: "article", name: "nombre inferido", url: "https://other.example.com/post" },
    fetchImpl,
  );
  assertEquals(result, {
    type: "article",
    name: "nombre inferido",
    url: "https://other.example.com/post",
    link: "https://other.example.com/post",
    imageUrl: undefined,
  });
});

Deno.test("una URL de artículo insegura (SSRF) nunca llega a fetchear, pero igual queda con link", async () => {
  let called = false;
  const fetchImpl: FetchLike = (() => {
    called = true;
    return Promise.reject(new Error("no debería llamarse"));
  }) as unknown as FetchLike;

  const result = await enrichMention(
    { type: "article", name: "nombre inferido", url: "http://169.254.169.254/latest/meta-data" },
    fetchImpl,
  );

  assertEquals(called, false);
  assertEquals(result, {
    type: "article",
    name: "nombre inferido",
    url: "http://169.254.169.254/latest/meta-data",
    link: "http://169.254.169.254/latest/meta-data",
  });
});

Deno.test("una excepción durante el fetch de Open Graph igual queda con link", async () => {
  const throwingFetch: FetchLike =
    (() => Promise.reject(new Error("network down"))) as unknown as FetchLike;
  const result = await enrichMention(
    { type: "article", name: "nombre inferido", url: "https://other.example.com/post" },
    throwingFetch,
  );
  assertEquals(result, {
    type: "article",
    name: "nombre inferido",
    url: "https://other.example.com/post",
    link: "https://other.example.com/post",
  });
});
