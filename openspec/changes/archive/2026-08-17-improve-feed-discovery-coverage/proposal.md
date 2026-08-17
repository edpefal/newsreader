## Why

El usuario intentó agregar `https://androidweekly.net/` y la detección automática de feed falló. Investigación confirmó dos causas concretas: (1) la lista de sufijos genéricos (`FeedUrlResolver`) no incluye `/rss.xml`, que es donde vive el feed real de ese sitio, y (2) el cliente HTTP no manda ningún header `Accept`, lo que hace que servidores con content negotiation estricto (como el sufijo `/rss/` de ese mismo sitio, que sí se prueba) respondan `406 Not Acceptable` en vez de servir el feed — aunque `curl` con su `Accept: */*` por default sí lo consigue. Además, el auto-descubrimiento vía `<link rel="alternate">` (la señal más confiable que existe, porque el sitio la declara explícitamente) hoy corre como último recurso secuencial, en vez de participar en la ráfaga paralela de candidatos junto al resto.

## What Changes

- `FeedUrlResolver._genericSuffixes` se amplía con `/rss.xml`, `/feed.xml` e `/index.xml`, sumados a los ya existentes (`/feed`, `/feed/`, `/rss/`, `/atom.xml`).
- `HttpPackageClient.get` manda `Accept: */*` en toda solicitud (comportamiento por default de cualquier cliente HTTP genérico, incluido `curl`) — sin esto, servidores con content negotiation estricto rechazan la solicitud aunque la ruta sea correcta.
- El auto-descubrimiento vía `<link rel="alternate">` deja de ser un tercer paso secuencial y pasa a extraerse del HTML de la etapa 1 (ya descargado, sin request adicional) e incorporarse como un candidato más de la ráfaga paralela de la etapa 2, con prioridad por encima de los sufijos genéricos y los casos de plataforma — es la señal más confiable disponible, ya que el sitio la declara explícitamente.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `feed-url-discovery`: se amplía la lista de sufijos genéricos probados; el auto-descubrimiento por `<link rel="alternate">` pasa de "último recurso" a candidato de la ráfaga paralela con prioridad alta; las solicitudes de descubrimiento ahora envían `Accept: */*`.

## Impact

- `lib/core/feed/feed_url_resolver.dart` (lista de sufijos genéricos)
- `lib/core/network/http_package_client.dart` (header `Accept` por default en `get`)
- `lib/features/sources/domain/usecases/add_source.dart` (reordenamiento de etapas: `<link rel="alternate">` pasa de etapa 3 secuencial a candidato de la etapa 2 paralela)
- `openspec/specs/feed-url-discovery/spec.md` (requirements actualizados)
- Sin impacto en `lib/features/sources/domain/usecases/import_opml.dart` más allá de heredar el header `Accept` por compartir `HttpClient` (comportamiento estrictamente más permisivo, no restrictivo)
