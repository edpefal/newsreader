## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Mensaje de error único cuando la detección automática falla
El sistema SHALL mostrar un mensaje de error genérico y único cuando ningún candidato (la URL original, ninguno de los candidatos heurísticos aplicables, ni el candidato de auto-descubrimiento por `<link rel="alternate">`) resulte ser un feed válido, indicando al usuario que pegue la URL exacta del feed RSS.

#### Scenario: Ningún candidato resulta válido
- **WHEN** el usuario ingresa una URL que no es un feed válido y ninguno de los candidatos aplicables (inserción de path, sufijos genéricos, variantes `www.`, ni el auto-descubrimiento por `<link rel="alternate">`) resulta serlo tampoco
- **THEN** el sistema muestra el mensaje "No pudimos detectar el feed automáticamente. Pega la URL exacta del feed RSS (por ejemplo, que termine en /feed o .xml)."
