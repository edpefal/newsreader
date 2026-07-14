## 1. FeedUrlResolver (core/feed)

- [x] 1.1 Crear `lib/core/feed/feed_url_resolver.dart` con la clase `FeedUrlResolver` y su método `List<String> candidatesFor(String rawUrl)`.
- [x] 1.2 Implementar la normalización a origin (scheme+host, sin path/query/fragment) usando `Uri` de `dart:core`.
- [x] 1.3 Implementar el matching de host por plataforma y la tabla de sufijos: Substack (`*.substack.com` → `/feed`), WordPress.com (`*.wordpress.com` → `/feed/`), Ghost Pro (`*.ghost.io` → `/rss/`).
- [x] 1.4 Asegurar que `candidatesFor` siempre incluya `rawUrl` como primer elemento, y el candidato heurístico (si aplica) como segundo.
- [x] 1.5 Asegurar que un host no reconocido devuelva únicamente `[rawUrl]`.
- [x] 1.6 Escribir `test/unit/core/feed/feed_url_resolver_test.dart` cubriendo: cada una de las 4 plataformas soportadas (con URL de home y con URL de artículo/post), host no reconocido, URL que ya es un feed exacto (debe seguir devolviendo esa URL como primer candidato).
- [x] 1.7 Agregar caso especial para el formato de perfil `substack.com/@usuario` (y `www.substack.com/@usuario`), transformándolo a `https://usuario.substack.com/feed`, con sus tests correspondientes.
- [x] 1.8 Verificar manualmente contra sitios reales de cada plataforma soportada (curl + parseo real) que la heurística efectivamente resuelve un feed válido; se descubrió que Beehiiv no tiene ruta de feed fija (URL generada manualmente por publicación) y se removió de `_platformSuffixes`, actualizando tests y artefactos de OpenSpec en consecuencia.

## 2. Excepción de dominio

- [x] 2.1 Agregar `FeedDiscoveryException` en `lib/core/errors/app_exception.dart`, siguiendo el patrón `sealed class AppException` existente, con el mensaje "No pudimos detectar el feed automáticamente. Pega la URL exacta del feed RSS (por ejemplo, que termine en /feed o .xml)."

## 3. Orquestación en AddSource

- [x] 3.1 Modificar `lib/features/sources/domain/usecases/add_source.dart` para inyectar/usar `FeedUrlResolver` y recorrer `candidatesFor(feedUrl)` en orden.
- [x] 3.2 Por cada candidato: intentar `HttpClient.get` + `FeedParser.parse`; en éxito, detener el loop y quedarse con `(candidato, feedData)`.
- [x] 3.3 Si `NetworkException` o `TimeoutException` ocurre en un intento, propagarla inmediatamente sin probar más candidatos.
- [x] 3.4 Si `ParseException` ocurre, continuar con el siguiente candidato; si se agotan todos, lanzar `FeedDiscoveryException`.
- [x] 3.5 Mover el chequeo `sourceRepository.sourceExists(...)` para que se ejecute una sola vez, después de resolver el candidato exitoso, usando la feed URL resuelta (no el input crudo).
- [x] 3.6 Actualizar `lib/core/di/injection.dart` para registrar/inyectar `FeedUrlResolver` donde corresponda.
- [x] 3.7 Escribir `test/unit/features/sources/domain/usecases/add_source_test.dart` (con mocktail) cubriendo: URL exacta de feed sigue funcionando igual que hoy; URL humana de plataforma soportada se resuelve vía candidato heurístico; host no reconocido y candidato heurístico fallido lanzan `FeedDiscoveryException`; error de red en el primer intento se propaga sin probar el candidato heurístico; duplicado se detecta sobre la feed URL final resuelta.

## 4. UI de AddSourceScreen

- [x] 4.1 Actualizar el texto explicativo en `lib/features/sources/presentation/screens/add_source_screen.dart` a "Pega el link de tu newsletter (o la URL del feed RSS si la tienes)."
- [x] 4.2 Actualizar el hint del `TextField` a `https://autor.substack.com`.
- [x] 4.3 Actualizar `test/widget/features/sources/add_source_screen_test.dart` si referencia el copy o hint anterior.

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` y resolver cualquier warning.
- [x] 5.2 Correr `flutter test test/unit/core/feed/ test/unit/features/sources/ test/widget/features/sources/` y confirmar que todo pasa.
