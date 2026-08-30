## 1. Backend: link de Amazon para menciones de libro

- [x] 1.1 En `supabase/functions/enrich-mentions/providers.ts`, agregar una función `buildAmazonSearchLink(name: string): string` que devuelva `https://www.amazon.com/s?k=${encodeURIComponent(name)}&i=stripbooks`.
- [x] 1.2 Cambiar `resolveBook` para que solo intente resolver `imageUrl` desde Google Books (best-effort); ya no debe devolver `link` desde `volumeInfo.infoLink`/`previewLink`.
- [x] 1.3 En `enrichMention`, para `mention.type === "book"`, setear siempre `link: buildAmazonSearchLink(mention.name)`, independientemente del resultado de `resolveBook`/Google Books (incluyendo el caso en que la consulta a Google Books falla o lanza excepción).
- [x] 1.4 Actualizar el comentario de cabecera de `enrichMention` (líneas ~108-118 de `providers.ts`) para reflejar que la regla "sin match → sin link" ya no aplica a `book`, solo a `podcast`/`music`.

## 2. Tests

- [x] 2.1 En `providers_test.ts`, actualizar el test "enriquece un libro con match en Google Books" para esperar `link` de Amazon (no el `infoLink` de Google Books) junto con el `imageUrl` de Google Books.
- [x] 2.2 Reemplazar el test "mención sin match se devuelve sin imageUrl ni link" (hoy cubre libro y queda desactualizado) por dos casos separados: uno para libro (sin match en Google Books → sin `imageUrl`, pero con `link` de Amazon) y uno para música/podcast (sin match → sin `imageUrl` ni `link`, como hoy).
- [x] 2.3 Agregar un test donde la consulta a Google Books de un libro falla (red o status no-ok) y verificar que igual se obtiene el `link` de Amazon, sin `imageUrl`.
- [x] 2.4 Correr `deno test` en `supabase/functions/enrich-mentions/` y confirmar que todos los tests pasan.

## 3. Specs y cierre

- [x] 3.1 Correr `openspec validate --change add-book-mention-amazon-link --strict` y resolver cualquier error.
- [x] 3.2 Confirmar con el usuario si desplegar `enrich-mentions` solo a `reevo` (prod) o también a `reevo-dev` (`--project-ref xgwnxhpdcrghrtdbrmpn`), y desplegar según lo acordado.
- [x] 3.3 Verificar manualmente (o pedirle al usuario que verifique) que un artículo con mención de libro sin match en Google Books ahora muestra la card tappeable y abre un link de búsqueda de Amazon válido. Confirmado por el usuario: el link funciona. La portada sigue mostrando el ícono genérico porque Google Books cortó el acceso anónimo a su API (cupo 0, ver bug separado) — no es una regresión de este change, ya que la resolución de `imageUrl` quedó intacta a propósito (ver design.md).
