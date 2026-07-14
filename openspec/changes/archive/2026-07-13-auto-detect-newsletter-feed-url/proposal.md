## Why

Hoy, para agregar una fuente el usuario necesita conocer y pegar la URL exacta del feed RSS/Atom (p. ej. `https://autor.substack.com/feed`). Varias plataformas de newsletter modernas (Substack, WordPress.com, Ghost) exponen su feed en una ruta fija y predecible a partir del dominio del newsletter, pero el usuario típicamente solo tiene a mano el link "humano" que comparte el autor (p. ej. `https://autor.substack.com/p/mi-articulo`). Exigir la URL exacta del feed es una fricción innecesaria que aleja a usuarios no técnicos de agregar fuentes.

## What Changes

- El campo de "Agregar newsletter" ahora acepta tanto la URL exacta del feed (comportamiento actual, sigue funcionando igual) como una URL "humana" del newsletter (home del newsletter o un artículo puntual).
- Cuando la URL pegada no es directamente un feed válido, el sistema intenta auto-detectar el feed real aplicando heurísticas de patrón de URL por plataforma conocida (Substack, WordPress.com, Ghost Pro), normalizando a origin (scheme+host) y probando el sufijo fijo de esa plataforma. Substack además reconoce el formato de perfil `substack.com/@usuario` (sin subdominio), transformándolo al subdominio correspondiente.
- Si la plataforma no es reconocida, o el candidato detectado tampoco resulta ser un feed válido, se muestra un SnackBar de error con un mensaje único y genérico indicando que no se pudo detectar el feed automáticamente y que se pegue la URL exacta del feed RSS.
- Errores de red o timeout durante la detección se propagan de inmediato (no se siguen probando candidatos), ya que un problema de conectividad afecta a cualquier candidato por igual.
- La verificación de fuente duplicada pasa a hacerse sobre la feed URL final ya resuelta (la que efectivamente parseó como feed válido), en vez de sobre la URL cruda ingresada por el usuario. **BREAKING** (cambio de comportamiento interno): un usuario que pegue la URL humana de una fuente ya agregada dejará de recibir el error de duplicado instantáneamente; lo recibirá después del intento de fetch+detección, una vez resuelta la feed URL real.
- Se actualiza el copy y el hint del campo de texto en `AddSourceScreen` para reflejar que ahora se acepta el link del newsletter, no solo el feed.
- Fuera de alcance explícito de este cambio (documentado como limitación conocida): dominios propios/custom domains de estas mismas plataformas (no detectables solo por hostname), Medium (requiere lógica de path, no de origin), y fuerza bruta de rutas comunes como último recurso.
- **Beehiiv se evaluó y se descartó del v1**: a diferencia de Substack/WordPress.com/Ghost, Beehiiv no expone el feed en una ruta fija — cada publicación genera manualmente una URL de feed única y aleatoria (terminada en `.xml`) desde su panel, y muchas publicaciones ni siquiera lo tienen habilitado. Se verificó contra una publicación real (`newsletterexamples.beehiiv.com/feed`) y devolvió el HTML del sitio, no un feed. No hay heurística de URL posible para esta plataforma.

## Capabilities

### New Capabilities
- `feed-url-discovery`: detección automática de la URL de feed RSS/Atom real a partir de una URL "humana" de newsletter, mediante heurísticas de patrón de URL por plataforma conocida (Substack, WordPress.com, Ghost Pro).

### Modified Capabilities
- `source-management`: el flujo de agregar fuente (`AddSourceScreen`/`AddSource`) ahora intenta primero la detección automática de feed antes de fallar, cambia el momento en que se verifica duplicado (sobre la feed URL final resuelta, no sobre el input crudo), y actualiza el copy de la pantalla para reflejar que acepta URLs de newsletter además de feeds exactos.

## Impact

- `lib/core/feed/`: nueva clase pura `FeedUrlResolver` (sin I/O), junto a `FeedParser`/`FeedData` existentes.
- `lib/core/errors/app_exception.dart`: nueva excepción `FeedDiscoveryException`.
- `lib/features/sources/domain/usecases/add_source.dart`: orquesta el loop de candidatos de `FeedUrlResolver`, reordena el chequeo de duplicado.
- `lib/features/sources/presentation/screens/add_source_screen.dart`: actualiza copy y hint.
- Sin nuevas dependencias de terceros; sin cambios de API pública ni de esquema de datos (Hive).
