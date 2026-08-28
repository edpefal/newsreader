import { assertEquals } from "jsr:@std/assert@1";
import { enrichMention, type FetchLike } from "./providers.ts";

function fakeFetch(body: unknown, ok = true): FetchLike {
  return (() =>
    Promise.resolve(
      new Response(JSON.stringify(body), { status: ok ? 200 : 500 }),
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
  assertEquals(result, { type: "book", name: "Un libro inexistente" });
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
