## Why

Hoy el `link` de una mención de tipo libro depende de que Google Books encuentre un match para el nombre y de que ese match traiga `infoLink`/`previewLink`. Cuando eso no pasa, la mención se muestra como texto plano sin ninguna acción: el usuario ve que se mencionó un libro pero no tiene forma de ir a ningún lado a verlo o comprarlo. Un link de búsqueda de Amazon, en cambio, siempre se puede construir a partir del nombre del libro sin depender de ningún proveedor externo, así que garantiza que toda mención de tipo libro tenga una acción útil.

## What Changes

- Para menciones de tipo `book`, el `link` deja de venir de Google Books (`infoLink`/`previewLink`) y pasa a construirse siempre como una URL de búsqueda de Amazon (`https://www.amazon.com/s?k=<nombre codificado>&i=stripbooks`), sin depender de si Google Books encontró match. **BREAKING** para el contrato de `enrichMention`: una mención de libro ya no puede quedar sin `link` (antes sí podía).
- Google Books se sigue consultando exclusivamente para obtener `imageUrl` (portada); si no hay match o falla, `imageUrl` queda ausente igual que hoy (la card cae al ícono placeholder, pero ahora sí es tappeable).
- Sin dominio localizado por idioma/país (siempre `amazon.com`) y sin tag de afiliado de Amazon Associates — ambos quedan explícitamente fuera de scope.
- Sin cambios en `podcast`/`music`: siguen dependiendo 100% de iTunes Search, con el mismo comportamiento de "sin match → sin link" que tienen hoy.
- Sin cambios en Flutter: `MentionCard` ya soporta tap cuando hay `link` y ya maneja `imageUrl` ausente con el ícono placeholder.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `article-mentions`: cambia el requirement "Enriquecimiento de menciones vía proveedor externo" — para libros, el link deja de depender del proveedor (Google Books) y pasa a construirse siempre a partir del nombre; el escenario "Mención sin match del proveedor se muestra igual" deja de aplicar a libros (solo sigue aplicando a podcast/música).

## Impact

- `supabase/functions/enrich-mentions/providers.ts`: función `resolveBook` — separa la resolución de `imageUrl` (Google Books, best-effort) de la construcción de `link` (siempre, sin red).
- `supabase/functions/enrich-mentions/providers_test.ts`: tests existentes de `resolveBook`/`enrichMention` para libros que asumen "sin match → sin link" quedan desactualizados y hay que ajustarlos.
- Requiere deploy de la Edge Function `enrich-mentions` a `reevo` y `reevo-dev` (confirmar con el usuario antes de dar el change por terminado, según CLAUDE.md).
- No afecta código Flutter ni traducciones (no se agrega texto nuevo visible al usuario).
