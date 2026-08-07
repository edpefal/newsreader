## 1. `FeedUrlResolver`: candidatos `www.<host>`

- [x] 1.1 En `candidatesFor()`, después de generar los sufijos genéricos sobre el host original, si el host no empieza ya con `www.`, agregar los mismos sufijos genéricos sobre `www.<host>` como candidatos adicionales (menor prioridad, van al final de la lista).
- [x] 1.2 Actualizar `test/unit/core/feed/feed_url_resolver_test.dart`: caso `notboring.co` con candidatos `www.notboring.co/feed` etc. al final de la lista, caso donde el host ya tiene `www.` (no duplica), y confirmar que el orden de prioridad pone los candidatos `www.` después de todos los del host original.

## 2. `HtmlFeedLinkExtractor`: extracción pura de `<link rel="alternate">`

- [x] 2.1 Agregar `html` como dependencia directa en `pubspec.yaml` (ya transitiva, formalizar el uso directo).
- [x] 2.2 Crear `lib/core/feed/html_feed_link_extractor.dart`: función pura `extract(String html, Uri baseUri) -> String?` que parsea el HTML con `package:html`, busca el primer `<link rel="alternate">` con `type` `application/rss+xml` o `application/atom+xml`, y devuelve su `href` resuelto contra `baseUri` (soporta href relativo y absoluto). Devuelve `null` si no encuentra ninguno.
- [x] 2.3 Crear `test/unit/core/feed/html_feed_link_extractor_test.dart`: casos con `href` relativo (como `simonwillison.net`), `href` absoluto, sin ningún link declarado, con varios links (toma el primero que matchee), atributos en distinto orden/mayúsculas, y HTML sin `<head>`/malformado (no debe tirar excepción, devuelve `null`).

## 3. `AddSource`: etapa 3 de auto-descubrimiento

- [x] 3.1 Modificar `_tryCandidate` (o agregar una variante para la etapa 1 específicamente) para que, cuando `_feedParser.parse()` lance `ParseException`, retenga el HTML descargado en vez de descartarlo — necesario solo para el candidato de la etapa 1 (`candidates.first`).
- [x] 3.2 En `_resolveFeed`, si la etapa 2 no produce ningún candidato válido, y hay HTML retenido de la etapa 1, pasarlo a `HtmlFeedLinkExtractor.extract()`. Si devuelve una URL, probarla como candidato final (mismo mecanismo que `_tryCandidate`, propagando `ParseException` como fallo final, no como excepción). Si no hay HTML retenido (etapa 1 falló por red, o la URL ya era un feed válido y nunca se llegó a la etapa 2), saltar directamente al mensaje de error existente.
- [x] 3.3 Actualizar `test/unit/features/sources/domain/usecases/add_source_test.dart`: caso donde la etapa 2 falla pero el HTML de la etapa 1 declara un link de feed válido (etapa 3 lo encuentra y lo usa), caso donde el HTML de la etapa 1 no declara ningún link (falla igual que hoy), y caso donde la etapa 1 falla por red (no llega a intentar la etapa 3).

## 4. Verificación

- [x] 4.1 Correr `flutter analyze` sin warnings nuevos.
- [x] 4.2 Correr `flutter test test/unit/core/feed/ test/unit/features/sources/` y confirmar que todo pasa.
- [x] 4.3 Probar manualmente en la app: agregar `notboring.co` y `simonwillison.net`, confirmar que ambos resuelven correctamente a su feed real.
