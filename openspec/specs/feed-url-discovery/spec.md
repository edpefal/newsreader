# Capability: Feed URL Discovery

## Purpose

Detección automática de la URL de feed RSS/Atom real a partir de una URL "humana" de newsletter (home o artículo puntual), mediante heurísticas de patrón de URL por plataforma conocida (Substack, WordPress.com, Ghost Pro).

---

## Requirements

### Requirement: Normalización de esquema faltante
El sistema SHALL, antes de generar cualquier candidato, normalizar la URL ingresada agregándole el esquema `https://` si no incluye ningún esquema, de forma que la URL "tal cual" y todos los candidatos derivados (inserción de path, sufijos genéricos) se construyan sobre una URL con esquema válido.

#### Scenario: Usuario ingresa un dominio sin esquema
- **WHEN** el usuario ingresa `stratechery.com` (sin `https://` ni `http://`)
- **THEN** el sistema normaliza la URL a `https://stratechery.com` antes de intentarla como feed directo y antes de derivar cualquier candidato heurístico

#### Scenario: Usuario ingresa una URL que ya incluye esquema
- **WHEN** el usuario ingresa `https://stratechery.com` o `http://stratechery.com`
- **THEN** el sistema no modifica la URL

---

### Requirement: Detección de feed URL por sufijo genérico sobre el dominio raíz
El sistema SHALL, cuando una URL ingresada no sea directamente un feed válido, intentar derivar la feed URL real normalizando la URL a su origin (scheme+host, descartando path, query y fragment) y probando una lista de sufijos genéricos de feed conocidos, sin condicionar el intento a que el host matchee un subdominio de plataforma reconocida: `/feed`, `/feed/`, `/rss/`, `/atom.xml`.

#### Scenario: Publicación de Substack en dominio propio se resuelve a su feed
- **WHEN** el usuario ingresa `https://stratechery.com/2024/algun-articulo`
- **THEN** el sistema intenta `https://stratechery.com/feed` como uno de los candidatos de feed, aunque el host no termine en `.substack.com`

#### Scenario: Blog de Ghost self-hosted o en dominio propio se resuelve a su feed
- **WHEN** el usuario ingresa `https://blog.miempresa.com/algun-post`
- **THEN** el sistema intenta `https://blog.miempresa.com/rss/` como uno de los candidatos de feed, aunque el host no termine en `.ghost.io`

#### Scenario: Publicación de Medium en dominio propio se resuelve a su feed
- **WHEN** el usuario ingresa `https://midominio.com/algun-articulo`
- **THEN** el sistema intenta `https://midominio.com/feed` como uno de los candidatos de feed

#### Scenario: Host sin ningún feed en las rutas genéricas no genera falsos positivos
- **WHEN** el usuario ingresa una URL cuyo dominio raíz no expone un feed válido en ninguna de las rutas genéricas
- **THEN** el sistema no encuentra ningún candidato válido entre los sufijos genéricos y continúa con los demás candidatos aplicables (casos de inserción de path) o falla la detección si no hay más candidatos

#### Scenario: Beehiiv no genera candidato heurístico específico de plataforma
- **WHEN** el usuario ingresa una URL de un host `*.beehiiv.com`
- **THEN** el sistema no aplica ningún caso de inserción de path específico de Beehiiv, aunque sí prueba los sufijos genéricos sobre el dominio raíz como con cualquier otro host

---

### Requirement: Sufijos genéricos también se prueban sobre la variante `www.` del host
El sistema SHALL, cuando el host de la URL normalizada no empiece ya con `www.`, agregar como candidatos adicionales los mismos sufijos genéricos de feed aplicados sobre el host con el prefijo `www.` antepuesto, con menor prioridad que los candidatos sobre el host tal cual fue ingresado.

#### Scenario: Dominio apex que solo redirige a www en la raíz
- **WHEN** el usuario ingresa `https://notboring.co` y ninguno de los sufijos genéricos sobre `notboring.co` resulta válido
- **THEN** el sistema intenta los mismos sufijos genéricos sobre `www.notboring.co` (ej. `https://www.notboring.co/feed`) como candidatos adicionales

#### Scenario: El host ya tiene el prefijo www
- **WHEN** el usuario ingresa una URL cuyo host ya empieza con `www.` (ej. `https://www.notboring.co`)
- **THEN** el sistema no genera un candidato `www.www.notboring.co` duplicado

#### Scenario: Los candidatos www tienen menor prioridad que los del host original
- **WHEN** tanto un sufijo genérico sobre el host original como el mismo sufijo sobre la variante `www.` resultan válidos
- **THEN** el sistema usa el candidato sobre el host original, no la variante `www.`

---

### Requirement: Detección del formato de perfil substack.com/@usuario
El sistema SHALL reconocer el formato de perfil de Substack donde el usuario va en el path en lugar del subdominio (`substack.com/@usuario` o `www.substack.com/@usuario`), y derivar el candidato de feed transformándolo al subdominio correspondiente (`https://usuario.substack.com/feed`).

#### Scenario: URL de perfil de Substack con @usuario en el path
- **WHEN** el usuario ingresa `https://substack.com/@ederperez`
- **THEN** el sistema intenta `https://ederperez.substack.com/feed` como candidato de feed

#### Scenario: URL de substack.com sin @usuario en el path no genera candidato de inserción
- **WHEN** el usuario ingresa una URL de `substack.com` cuyo primer segmento de path no comienza con `@` (p. ej. `https://substack.com/discover`)
- **THEN** el sistema no genera ningún candidato de inserción de Substack para esa URL

---

### Requirement: Detección de perfil y publicación de Medium
El sistema SHALL reconocer las URLs de perfil de Medium (`medium.com/@usuario` o `usuario.medium.com`) y de publicación (`medium.com/<slug-de-publicación>`), y derivar el candidato de feed insertando el segmento `/feed` inmediatamente después del host, antes del resto del path.

#### Scenario: URL de perfil de Medium con @usuario en el path
- **WHEN** el usuario ingresa `https://medium.com/@ederperez`
- **THEN** el sistema intenta `https://medium.com/feed/@ederperez` como candidato de feed

#### Scenario: URL de perfil de Medium con subdominio propio
- **WHEN** el usuario ingresa `https://ederperez.medium.com`
- **THEN** el sistema intenta `https://ederperez.medium.com/feed` como candidato de feed

#### Scenario: URL de publicación de Medium
- **WHEN** el usuario ingresa `https://medium.com/una-publicacion/algun-articulo`
- **THEN** el sistema intenta `https://medium.com/feed/una-publicacion` como candidato de feed

---

### Requirement: La URL ingresada tal cual siempre se intenta primero, en solitario
El sistema SHALL intentar siempre la URL ingresada por el usuario como feed directo antes de aplicar cualquier heurística de detección, y SHALL esperar el resultado de ese intento antes de disparar cualquier candidato heurístico adicional.

#### Scenario: Usuario pega la feed URL exacta
- **WHEN** el usuario ingresa una URL que ya es un feed RSS/Atom válido
- **THEN** el sistema la usa directamente sin disparar ningún candidato heurístico

#### Scenario: URL ingresada no es un feed válido
- **WHEN** el usuario ingresa una URL que no resulta ser un feed válido por sí misma
- **THEN** el sistema recién entonces dispara los candidatos heurísticos aplicables

---

### Requirement: Los candidatos heurísticos se prueban en paralelo con prioridad determinista
El sistema SHALL, al pasar a la etapa de candidatos heurísticos, disparar todos los candidatos aplicables (casos de inserción de path específicos de plataforma y sufijos genéricos) de forma concurrente, y SHALL resolver el candidato ganador según un orden de prioridad fijo — primero los casos de inserción de path específicos de plataforma, luego los sufijos genéricos, en el orden en que están definidos — sin que el resultado dependa de cuál candidato responda primero por timing de red.

#### Scenario: Un candidato de menor prioridad responde antes mientras uno de mayor prioridad también es válido
- **WHEN** el host matchea un caso de inserción de plataforma y ese candidato resulta válido, pero un candidato de sufijo genérico de menor prioridad responde exitosamente primero por ser más rápido en la red
- **THEN** el sistema usa el candidato de inserción de plataforma (mayor prioridad), no el que respondió primero

#### Scenario: Resultado estable entre corridas con el mismo input
- **WHEN** el mismo host se resuelve más de una vez y más de un candidato resultaría válido
- **THEN** el sistema elige siempre el mismo candidato ganador, independientemente de variaciones en el tiempo de respuesta de red entre corridas

---

### Requirement: Un error de red en un candidato heurístico individual no aborta la ráfaga en paralelo
El sistema SHALL, durante la etapa de candidatos heurísticos, esperar el resultado de todos los candidatos en vuelo antes de decidir éxito o fallo, de forma que un error de red o timeout en un candidato individual no impida que otro candidato en la misma ráfaga sea evaluado. Un error de red o timeout al intentar la URL ingresada tal cual (antes de pasar a la etapa de candidatos heurísticos) SHALL seguir abortando la detección de inmediato, sin pasar a la etapa de candidatos heurísticos.

#### Scenario: Un candidato heurístico falla por red pero otro candidato de la misma ráfaga es válido
- **WHEN** durante la etapa de candidatos heurísticos, un candidato falla por error de red mientras otro candidato en vuelo resulta ser un feed válido
- **THEN** el sistema usa el candidato válido, sin que el error de red del otro candidato aborte la detección

#### Scenario: Error de red en la URL ingresada tal cual aborta antes de la etapa heurística
- **WHEN** el intento de obtener la URL ingresada tal cual falla por falta de conexión o timeout
- **THEN** el sistema propaga ese error de inmediato y no dispara ningún candidato heurístico

---

### Requirement: Auto-descubrimiento de feed vía `<link rel="alternate">` como último recurso
El sistema SHALL, cuando ni la URL ingresada ni ninguno de los candidatos heurísticos (inserción de path, sufijos genéricos, variantes `www.`) resulten en un feed válido, buscar en el HTML ya descargado al intentar la URL ingresada tal cual (etapa 1) un elemento `<link rel="alternate">` cuyo atributo `type` sea `application/rss+xml` o `application/atom+xml`, y probar la URL de su atributo `href` (resuelta contra la URL base correspondiente) como un candidato final antes de fallar la detección. El sistema NO SHALL realizar ninguna solicitud de red adicional para obtener ese HTML — reusa exclusivamente el contenido ya descargado en la etapa 1.

#### Scenario: El sitio declara su feed en el HTML pero no expone ningún sufijo genérico
- **WHEN** el usuario ingresa `https://simonwillison.net` y ninguno de los sufijos genéricos ni variantes `www.` resulta válido, pero el HTML descargado en la etapa 1 contiene `<link rel="alternate" type="application/atom+xml" href="/atom/everything/">`
- **THEN** el sistema intenta `https://simonwillison.net/atom/everything/` como candidato final

#### Scenario: El HTML no declara ningún link de feed
- **WHEN** ninguno de los candidatos anteriores resulta válido y el HTML de la etapa 1 no contiene ningún `<link rel="alternate">` de tipo RSS o Atom
- **THEN** el sistema falla la detección con el mismo mensaje de error ya existente, sin intentar ninguna solicitud adicional

#### Scenario: La etapa 1 no descargó HTML (falló por red, o la URL ingresada ya era un feed válido)
- **WHEN** la etapa 1 no tiene contenido HTML disponible para inspeccionar (porque falló por red/timeout, o porque la URL ingresada ya era un feed válido y nunca se llegó a esta etapa)
- **THEN** el sistema no intenta el auto-descubrimiento por `<link rel="alternate">`, siguiendo el comportamiento ya existente para esos casos

#### Scenario: `href` relativo se resuelve contra la URL base
- **WHEN** el `href` del `<link rel="alternate">` encontrado es una ruta relativa (ej. `/atom/everything/`, sin esquema ni host)
- **THEN** el sistema la resuelve contra el scheme y host de la URL ingresada en la etapa 1, no la usa tal cual

---

### Requirement: Mensaje de error único cuando la detección automática falla
El sistema SHALL mostrar un mensaje de error genérico y único cuando ningún candidato (la URL original, ninguno de los candidatos heurísticos aplicables, ni el candidato de auto-descubrimiento por `<link rel="alternate">`) resulte ser un feed válido, indicando al usuario que pegue la URL exacta del feed RSS.

#### Scenario: Ningún candidato resulta válido
- **WHEN** el usuario ingresa una URL que no es un feed válido y ninguno de los candidatos aplicables (inserción de path, sufijos genéricos, variantes `www.`, ni el auto-descubrimiento por `<link rel="alternate">`) resulta serlo tampoco
- **THEN** el sistema muestra el mensaje "No pudimos detectar el feed automáticamente. Pega la URL exacta del feed RSS (por ejemplo, que termine en /feed o .xml)."
