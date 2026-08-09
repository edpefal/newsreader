## ADDED Requirements

### Requirement: Mapeo de `<summary type="html">` a contenido cuando el ítem Atom no trae `<content>`
El sistema SHALL, al procesar un ítem de un feed Atom que no incluya un elemento `<content>` (ni su equivalente `content:encoded`), usar el valor de su `<summary>` como `content_html` del artículo, en vez de dejarlo vacío. El sistema NO SHALL asignar ese mismo valor de `<summary>` a `excerpt` en este caso.

#### Scenario: Ítem Atom con solo `<summary type="html">`, sin `<content>`
- **WHEN** el servidor procesa un ítem cuyo feed Atom no expone `<content>` pero sí `<summary type="html">`
- **THEN** el artículo creado tiene `content_html` igual al valor (ya HTML, no texto plano) de `<summary>`

#### Scenario: Ítem con `<content>` presente no se ve afectado
- **WHEN** el servidor procesa un ítem (Atom o RSS) que sí expone `<content>`/`content:encoded`
- **THEN** `content_html` sigue derivándose de ese campo, sin considerar `<summary>`

#### Scenario: `excerpt` no recibe HTML crudo del `<summary>` consumido como contenido
- **WHEN** un ítem Atom no tiene `<content>` y su `<summary>` se usó como `content_html`
- **THEN** el `excerpt` del artículo no queda con ese mismo HTML crudo — solo se deriva de un resumen en texto plano si el feed lo provee explícitamente, o queda vacío
