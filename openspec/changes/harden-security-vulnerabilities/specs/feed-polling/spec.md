## ADDED Requirements

### Requirement: Validación de URL pública antes de hacer fetch de una fuente
El sistema SHALL validar, antes de hacer fetch del `feed_url` de una fuente, que la URL use el esquema `http` o `https` y que su host no resuelva a `localhost`, a un rango de IP privado o reservado (loopback, link-local, RFC 1918), ni a metadata de infraestructura en la nube (ej. `169.254.169.254`). Si la validación falla, el sistema SHALL tratar esa fuente como fallida (mismo comportamiento que un timeout o XML inválido, ver Requirement "Un fallo en una fuente no interrumpe el fetch de las demás"), sin hacer ninguna request de red hacia esa URL.

#### Scenario: Fuente con feed_url apuntando a un rango de IP privado
- **WHEN** el servidor va a sincronizar una fuente cuyo `feed_url` resuelve a una IP dentro de un rango privado o reservado (ej. `http://169.254.169.254/`, `http://127.0.0.1/`, `http://10.0.0.5/`)
- **THEN** el sistema no hace ninguna request hacia esa URL, marca esa fuente como fallida, y continúa procesando las demás fuentes del usuario normalmente

#### Scenario: Fuente con feed_url de esquema distinto de http/https
- **WHEN** el servidor va a sincronizar una fuente cuyo `feed_url` usa un esquema distinto de `http`/`https` (ej. `file://`, `ftp://`)
- **THEN** el sistema no hace ninguna request hacia esa URL y marca esa fuente como fallida

#### Scenario: Fuente con feed_url público válido
- **WHEN** el servidor va a sincronizar una fuente cuyo `feed_url` es una URL `http`/`https` que resuelve a un host público
- **THEN** el sistema hace el fetch normalmente, sin cambios respecto del comportamiento existente
