import { assertEquals } from "jsr:@std/assert@1";
import { stripSourceLabels } from "./strip_source_label.ts";

const SOURCES = ["TechCrunch", "Stratechery by Ben Thompson"];

Deno.test("quita 'Fuente:' cuando el resto es una fuente conocida", () => {
  const input = "Fuente: TechCrunch\nPárrafo de TechCrunch.";
  assertEquals(
    stripSourceLabels(input, SOURCES),
    "TechCrunch\nPárrafo de TechCrunch.",
  );
});

Deno.test("no distingue mayúsculas y cubre Source: y 'Source :'", () => {
  assertEquals(
    stripSourceLabels("fuente: TechCrunch\nP.", SOURCES),
    "TechCrunch\nP.",
  );
  assertEquals(
    stripSourceLabels("Source: TechCrunch\nP.", SOURCES),
    "TechCrunch\nP.",
  );
  assertEquals(
    stripSourceLabels("Source : TechCrunch\nP.", SOURCES),
    "TechCrunch\nP.",
  );
});

Deno.test("un bloque sin etiqueta queda exactamente igual", () => {
  const input = "TechCrunch\nPárrafo de TechCrunch.";
  assertEquals(stripSourceLabels(input, SOURCES), input);
});

Deno.test("'Fuente: desconocida' no se toca si no es una fuente conocida", () => {
  const input = "Fuente: desconocida\nPárrafo.";
  assertEquals(stripSourceLabels(input, SOURCES), input);
});

Deno.test("la palabra 'Fuente:' dentro del párrafo no se toca", () => {
  const input =
    "TechCrunch\nPrimera línea del párrafo.\nFuente: según el reporte.";
  assertEquals(stripSourceLabels(input, SOURCES), input);
});

Deno.test("mezcla de bloques con y sin etiqueta, conservando la separación", () => {
  const input = [
    "Fuente: TechCrunch\nPárrafo A.",
    "Stratechery by Ben Thompson\nPárrafo B.",
  ].join("\n\n");
  assertEquals(
    stripSourceLabels(input, SOURCES),
    "TechCrunch\nPárrafo A.\n\nStratechery by Ben Thompson\nPárrafo B.",
  );
});

Deno.test("tolera espacios alrededor de la etiqueta y del nombre", () => {
  assertEquals(
    stripSourceLabels("  Fuente:   TechCrunch  \nP.", SOURCES),
    "TechCrunch\nP.",
  );
});

Deno.test("una fuente cuyo nombre real empieza con la etiqueta no se altera", () => {
  const input = "Fuente: Reporte\nPárrafo.";
  assertEquals(stripSourceLabels(input, ["Fuente: Reporte"]), input);
});

Deno.test("una fuente con dos puntos que no empieza con la etiqueta no se altera", () => {
  const input = "Reuters: World News\nPárrafo.";
  assertEquals(stripSourceLabels(input, ["Reuters: World News"]), input);
});

Deno.test("sin fuentes conocidas devuelve el texto sin cambios", () => {
  const input = "Fuente: TechCrunch\nPárrafo.";
  assertEquals(stripSourceLabels(input, []), input);
});
