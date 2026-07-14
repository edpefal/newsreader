## ADDED Requirements

### Requirement: Detección de feed URL por patrón de plataforma conocida
El sistema SHALL, cuando una URL ingresada no sea directamente un feed válido, intentar derivar la feed URL real normalizando la URL a su origin (scheme+host, descartando path, query y fragment) y aplicando el sufijo fijo correspondiente si el host matchea una de las plataformas soportadas: Substack (`*.substack.com` → `/feed`), WordPress.com (`*.wordpress.com` → `/feed/`), Ghost Pro (`*.ghost.io` → `/rss/`).

#### Scenario: URL de artículo de Substack se resuelve a su feed
- **WHEN** el usuario ingresa `https://autor.substack.com/p/mi-articulo`
- **THEN** el sistema intenta `https://autor.substack.com/feed` como candidato de feed

#### Scenario: URL de WordPress.com se resuelve a su feed
- **WHEN** el usuario ingresa `https://autor.wordpress.com/2024/01/01/algun-post`
- **THEN** el sistema intenta `https://autor.wordpress.com/feed/` como candidato de feed

#### Scenario: URL de Ghost Pro se resuelve a su feed
- **WHEN** el usuario ingresa `https://autor.ghost.io`
- **THEN** el sistema intenta `https://autor.ghost.io/rss/` como candidato de feed

#### Scenario: Host no reconocido no genera candidato heurístico
- **WHEN** el usuario ingresa una URL cuyo host no matchea ninguna plataforma soportada (p. ej. dominio propio o plataforma no cubierta)
- **THEN** el sistema no genera ningún candidato adicional más allá de la URL original ingresada

#### Scenario: Beehiiv no genera candidato heurístico
- **WHEN** el usuario ingresa una URL de un host `*.beehiiv.com`
- **THEN** el sistema no genera ningún candidato adicional más allá de la URL original ingresada, ya que Beehiiv no expone el feed en una ruta fija y predecible

### Requirement: Detección del formato de perfil substack.com/@usuario
El sistema SHALL reconocer el formato de perfil de Substack donde el usuario va en el path en lugar del subdominio (`substack.com/@usuario` o `www.substack.com/@usuario`), y derivar el candidato de feed transformándolo al subdominio correspondiente (`https://usuario.substack.com/feed`).

#### Scenario: URL de perfil de Substack con @usuario en el path
- **WHEN** el usuario ingresa `https://substack.com/@ederperez`
- **THEN** el sistema intenta `https://ederperez.substack.com/feed` como candidato de feed

#### Scenario: URL de substack.com sin @usuario en el path no genera candidato
- **WHEN** el usuario ingresa una URL de `substack.com` cuyo primer segmento de path no comienza con `@` (p. ej. `https://substack.com/discover`)
- **THEN** el sistema no genera ningún candidato adicional más allá de la URL original ingresada

### Requirement: La URL ingresada tal cual siempre se intenta primero
El sistema SHALL intentar siempre la URL ingresada por el usuario como feed directo antes de aplicar cualquier heurística de detección, preservando la posibilidad de pegar la URL exacta del feed.

#### Scenario: Usuario pega la feed URL exacta
- **WHEN** el usuario ingresa una URL que ya es un feed RSS/Atom válido
- **THEN** el sistema la usa directamente sin intentar ningún candidato heurístico

### Requirement: Errores de red abortan la detección sin probar más candidatos
El sistema SHALL propagar inmediatamente cualquier error de red o timeout ocurrido al intentar un candidato, sin continuar probando los candidatos restantes.

#### Scenario: Falla de conectividad en el primer intento
- **WHEN** el intento de obtener la URL ingresada falla por falta de conexión o timeout
- **THEN** el sistema propaga ese error de inmediato y no intenta ningún candidato heurístico adicional

### Requirement: Mensaje de error único cuando la detección automática falla
El sistema SHALL mostrar un mensaje de error genérico y único cuando ningún candidato (la URL original ni, si aplica, el candidato heurístico) resulte ser un feed válido, indicando al usuario que pegue la URL exacta del feed RSS.

#### Scenario: Ninguna plataforma reconocida y URL original no es un feed
- **WHEN** el usuario ingresa una URL de un host no reconocido y que tampoco es un feed válido
- **THEN** el sistema muestra el mensaje "No pudimos detectar el feed automáticamente. Pega la URL exacta del feed RSS (por ejemplo, que termine en /feed o .xml)."

#### Scenario: Plataforma reconocida pero el candidato heurístico tampoco es un feed válido
- **WHEN** el usuario ingresa una URL de una plataforma soportada, pero ni la URL original ni el candidato heurístico resultan ser un feed válido
- **THEN** el sistema muestra el mismo mensaje "No pudimos detectar el feed automáticamente. Pega la URL exacta del feed RSS (por ejemplo, que termine en /feed o .xml)."
