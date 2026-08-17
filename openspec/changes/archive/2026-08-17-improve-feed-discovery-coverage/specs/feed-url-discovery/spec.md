## MODIFIED Requirements

### Requirement: Detección de feed URL por sufijo genérico sobre el dominio raíz
El sistema SHALL, cuando una URL ingresada no sea directamente un feed válido, intentar derivar la feed URL real normalizando la URL a su origin (scheme+host, descartando path, query y fragment) y probando una lista de sufijos genéricos de feed conocidos, sin condicionar el intento a que el host matchee un subdominio de plataforma reconocida: `/feed`, `/feed/`, `/rss/`, `/atom.xml`, `/rss.xml`, `/feed.xml`, `/index.xml`.

#### Scenario: Publicación de Substack en dominio propio se resuelve a su feed
- **WHEN** el usuario ingresa `https://stratechery.com/2024/algun-articulo`
- **THEN** el sistema intenta `https://stratechery.com/feed` como uno de los candidatos de feed, aunque el host no termine en `.substack.com`

#### Scenario: Blog de Ghost self-hosted o en dominio propio se resuelve a su feed
- **WHEN** el usuario ingresa `https://blog.miempresa.com/algun-post`
- **THEN** el sistema intenta `https://blog.miempresa.com/rss/` como uno de los candidatos de feed, aunque el host no termine en `.ghost.io`

#### Scenario: Publicación de Medium en dominio propio se resuelve a su feed
- **WHEN** el usuario ingresa `https://midominio.com/algun-articulo`
- **THEN** el sistema intenta `https://midominio.com/feed` como uno de los candidatos de feed

#### Scenario: Sitio que expone su feed en /rss.xml en vez de las rutas ya cubiertas
- **WHEN** el usuario ingresa la URL de un sitio cuyo feed vive en `/rss.xml` (y no en `/feed`, `/feed/`, `/rss/` ni `/atom.xml`)
- **THEN** el sistema intenta `<origin>/rss.xml` como uno de los candidatos de feed

#### Scenario: Host sin ningún feed en las rutas genéricas no genera falsos positivos
- **WHEN** el usuario ingresa una URL cuyo dominio raíz no expone un feed válido en ninguna de las rutas genéricas
- **THEN** el sistema no encuentra ningún candidato válido entre los sufijos genéricos y continúa con los demás candidatos aplicables (inserción de path, auto-descubrimiento) o falla la detección si no hay más candidatos

#### Scenario: Beehiiv no genera candidato heurístico específico de plataforma
- **WHEN** el usuario ingresa una URL de un host `*.beehiiv.com`
- **THEN** el sistema no aplica ningún caso de inserción de path específico de Beehiiv, aunque sí prueba los sufijos genéricos sobre el dominio raíz como con cualquier otro host

---

### Requirement: Los candidatos heurísticos se prueban en paralelo con prioridad determinista
El sistema SHALL, al pasar a la etapa de candidatos heurísticos, disparar todos los candidatos aplicables (el candidato de auto-descubrimiento por `<link rel="alternate">` si el HTML de la etapa 1 lo reveló, los casos de inserción de path específicos de plataforma, y los sufijos genéricos) de forma concurrente, y SHALL resolver el candidato ganador según un orden de prioridad fijo — primero el candidato de auto-descubrimiento por `<link rel="alternate">`, luego los casos de inserción de path específicos de plataforma, luego los sufijos genéricos, en el orden en que están definidos — sin que el resultado dependa de cuál candidato responda primero por timing de red.

#### Scenario: Un candidato de menor prioridad responde antes mientras uno de mayor prioridad también es válido
- **WHEN** el host matchea un caso de inserción de plataforma y ese candidato resulta válido, pero un candidato de sufijo genérico de menor prioridad responde exitosamente primero por ser más rápido en la red
- **THEN** el sistema usa el candidato de inserción de plataforma (mayor prioridad), no el que respondió primero

#### Scenario: El candidato de auto-descubrimiento tiene prioridad sobre un caso de plataforma
- **WHEN** el HTML de la etapa 1 declara un `<link rel="alternate">` válido y, en paralelo, un caso de inserción de plataforma también resulta ser un feed válido
- **THEN** el sistema usa el candidato declarado por `<link rel="alternate">`, no el de inserción de plataforma

#### Scenario: Resultado estable entre corridas con el mismo input
- **WHEN** el mismo host se resuelve más de una vez y más de un candidato resultaría válido
- **THEN** el sistema elige siempre el mismo candidato ganador, independientemente de variaciones en el tiempo de respuesta de red entre corridas

---

### Requirement: Auto-descubrimiento de feed vía `<link rel="alternate">` con prioridad alta en la ráfaga paralela
El sistema SHALL, al pasar a la etapa de candidatos heurísticos, buscar en el HTML ya descargado al intentar la URL ingresada tal cual (etapa 1) un elemento `<link rel="alternate">` cuyo atributo `type` sea `application/rss+xml` o `application/atom+xml`, y — si lo encuentra — incorporar la URL de su atributo `href` (resuelta contra la URL base correspondiente) como un candidato más de la ráfaga paralela de la etapa 2, con la prioridad más alta entre todos los candidatos heurísticos. El sistema NO SHALL realizar ninguna solicitud de red adicional para obtener ese HTML — reusa exclusivamente el contenido ya descargado en la etapa 1. Este candidato participa en la misma ráfaga concurrente que el resto (no es un paso secuencial posterior).

#### Scenario: El sitio declara su feed en el HTML pero no expone ningún sufijo genérico
- **WHEN** el usuario ingresa `https://simonwillison.net` y el HTML descargado en la etapa 1 contiene `<link rel="alternate" type="application/atom+xml" href="/atom/everything/">`
- **THEN** el sistema intenta `https://simonwillison.net/atom/everything/` como uno de los candidatos de la ráfaga paralela, junto con los sufijos genéricos y casos de plataforma, no como un paso posterior a que esos fallen

#### Scenario: El HTML no declara ningún link de feed
- **WHEN** el HTML de la etapa 1 no contiene ningún `<link rel="alternate">` de tipo RSS o Atom
- **THEN** el sistema no agrega ningún candidato de auto-descubrimiento a la ráfaga, y la detección continúa solo con los demás candidatos aplicables

#### Scenario: La etapa 1 no descargó HTML (falló por red, o la URL ingresada ya era un feed válido)
- **WHEN** la etapa 1 no tiene contenido HTML disponible para inspeccionar (porque falló por red/timeout, o porque la URL ingresada ya era un feed válido y nunca se llegó a esta etapa)
- **THEN** el sistema no intenta el auto-descubrimiento por `<link rel="alternate">`, siguiendo el comportamiento ya existente para esos casos

#### Scenario: `href` relativo se resuelve contra la URL base
- **WHEN** el `href` del `<link rel="alternate">` encontrado es una ruta relativa (ej. `/atom/everything/`, sin esquema ni host)
- **THEN** el sistema la resuelve contra el scheme y host de la URL ingresada en la etapa 1, no la usa tal cual

## ADDED Requirements

### Requirement: Envío de un header Accept permisivo en solicitudes de descubrimiento
El sistema SHALL enviar el header `Accept: */*` en toda solicitud HTTP GET realizada durante la detección automática de feed (la URL ingresada tal cual y cada candidato heurístico), de forma que servidores que implementan content negotiation estricto sobre ese header no rechacen una respuesta válida solo por la ausencia del header.

#### Scenario: Un candidato responde distinto según el header Accept enviado
- **WHEN** un candidato de feed responde con contenido válido únicamente si la solicitud incluye `Accept: */*`, y respondería con un error (ej. `406 Not Acceptable`) sin ese header
- **THEN** el sistema, al enviar `Accept: */*` en la solicitud, recibe y evalúa el contenido válido en vez del error
