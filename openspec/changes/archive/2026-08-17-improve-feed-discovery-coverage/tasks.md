## 1. Ampliar sufijos genéricos

- [x] 1.1 Agregar `/rss.xml`, `/feed.xml` e `/index.xml` a `FeedUrlResolver._genericSuffixes` en `lib/core/feed/feed_url_resolver.dart`.
- [x] 1.2 Actualizar/agregar tests en `test/unit/core/feed/feed_url_resolver_test.dart` cubriendo los tres sufijos nuevos (host original y variante `www.`).

## 2. Header Accept permisivo

- [x] 2.1 En `lib/core/network/http_package_client.dart`, mandar `Accept: */*` en toda solicitud `get`.
- [x] 2.2 Agregar/actualizar test que verifique que el header se envía (usando un cliente HTTP mockeado, ej. `mocktail` + `http.Client` fake o interceptando la request). **Hecho** — nuevo `test/unit/core/network/http_package_client_test.dart` con `package:http/testing.dart` `MockClient`.

## 3. Reordenar auto-descubrimiento por `<link rel="alternate">`

- [x] 3.1 En `lib/features/sources/domain/usecases/add_source.dart`, mover la extracción de `HtmlFeedLinkExtractor` a antes de lanzar `Future.wait` sobre los candidatos heurísticos (reusando el HTML ya descargado en la etapa 1, sin request nuevo).
- [x] 3.2 Anteponer el candidato descubierto (si existe) a la lista de candidatos heurísticos, de forma que tenga la prioridad más alta al resolver el ganador según el orden ya existente (no por timing de red).
- [x] 3.3 Eliminar el paso secuencial de "etapa 3" que quedaba después de que fallara toda la etapa 2.
- [x] 3.4 Actualizar `test/unit/features/sources/domain/usecases/add_source_test.dart`: casos existentes de auto-descubrimiento deben seguir pasando con el nuevo flujo paralelo; agregar caso donde el link descubierto gana sobre un candidato de plataforma que también resuelve.

## 4. Verificación

- [x] 4.1 Correr `flutter test` completo. **Hecho** — 374 tests, todos pasan.
- [x] 4.2 Correr `flutter analyze` sin warnings. **Hecho** — sin issues.
- [x] 4.3 Probar manualmente agregando `https://androidweekly.net/` desde la app y confirmar que ahora se agrega correctamente. **Hecho** — reproducido con las clases reales de producción (`AddSource` + `HttpPackageClient` + `FeedUrlResolver` + `WebfeedFeedParser`) contra la red real: resuelve a `https://androidweekly.net/rss/` (el header `Accept: */*` destrabó ese candidato, que tiene más prioridad que `/rss.xml` en la lista) con `name="Android Weekly"`. Ambos fixes se confirman funcionando juntos.
