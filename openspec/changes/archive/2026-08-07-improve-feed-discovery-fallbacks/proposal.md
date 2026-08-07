## Why

Al probar la detección automática de feed contra sitios reales (`notboring.co`, `simonwillison.net`), ambos fallaron y cayeron al fallback de generar un email, aunque los dos publican un feed RSS/Atom perfectamente válido. Son dos causas distintas, ninguna cubierta por los sufijos genéricos ni los casos de inserción de plataforma actuales:

- `notboring.co` (sin `www`) solo redirige a `www.notboring.co` en la ruta raíz (`/`); cualquier otra ruta (`/feed`, `/rss/`, etc.) devuelve 404 directo sin redirigir. El feed real vive en `https://www.notboring.co/feed` — nunca se prueba porque el resolver solo usa el host tal cual lo escribió el usuario.
- `simonwillison.net` no expone ninguno de los sufijos genéricos soportados; su feed vive en un path completamente arbitrario (`/atom/everything/`) que ningún set fijo de sufijos puede predecir. La propia página, sin embargo, lo declara en su `<head>` vía `<link rel="alternate" type="application/atom+xml" href="/atom/everything/">` — el mecanismo estándar de auto-descubrimiento de feeds que usan los lectores RSS reales.

## What Changes

- Agregar la variante `www.<host>` como candidatos adicionales de menor prioridad en `FeedUrlResolver`, cuando el host ingresado no empieza ya con `www.` — mismos sufijos genéricos, sobre el subdominio `www`.
- Agregar una tercera etapa de resolución en `AddSource`, solo si las etapas 1 y 2 fallan: parsear el HTML ya descargado en la etapa 1 (la URL tal cual el usuario la ingresó) buscando un `<link rel="alternate" type="application/rss+xml">` o `type="application/atom+xml">` en el `<head>`, y probar esa URL como último candidato. No dispara ninguna request adicional para obtener el HTML — reusa el body que la etapa 1 ya bajó al fallar el parseo como feed.
- Nueva dependencia directa a `package:html` (ya presente de forma transitiva vía `flutter_widget_from_html`) para parsear el `<head>` de forma robusta, en vez de una heurística por regex.
- El mensaje final de error ("No pudimos detectar el feed automáticamente...") se mantiene igual — se agrega un candidato más a probar antes de llegar a ese mensaje, no un mensaje ni una etapa visible nueva en la UI (etapa 3 sigue mostrando "Buscando en varios lugares posibles...", el mismo estado que ya cubre la etapa 2).

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `feed-url-discovery`: se agregan candidatos de variante `www.` y una etapa de auto-descubrimiento por `<link rel="alternate">` del HTML de la etapa 1, como último recurso antes de fallar la detección.

## Impact

- `lib/core/feed/feed_url_resolver.dart`: agregar generación de candidatos `www.<host>` sobre los sufijos genéricos existentes.
- Nueva clase, ej. `lib/core/feed/html_feed_link_extractor.dart`: función pura (HTML string → URL de feed candidata o `null`), sin I/O, parsea `<link rel="alternate">` con `package:html`.
- `lib/features/sources/domain/usecases/add_source.dart`: la etapa 1 (`_tryCandidate` para el `rawUrl`) debe retener el HTML descargado cuando falla el parseo como feed, para pasarlo a la nueva etapa 3 si las etapas 1 y 2 no producen un feed válido.
- `pubspec.yaml`: agregar `html` como dependencia directa (ya transitiva).
- Tests unitarios nuevos/extendidos en `test/unit/core/feed/feed_url_resolver_test.dart`, un test file nuevo para el extractor, y extensión de `test/unit/features/sources/domain/usecases/add_source_test.dart` para la etapa 3.
- No afecta la UI más allá de un candidato más probado antes de mostrar el error — ningún estado ni mensaje nuevo.
