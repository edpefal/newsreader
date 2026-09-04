# Spec: Article Mentions

## Purpose

Define cómo el sistema detecta menciones a libros, podcasts, música y artículos citados dentro de un artículo, cómo las enriquece con datos de proveedores externos (portada e link), y cómo se presentan y comportan en la UI, incluyendo el caso en que no se encuentra un match.

## Requirements

### Requirement: Detección de menciones al generar el resumen de un artículo

Al generar el resumen de un artículo (capability `article-summaries`), el sistema SHALL además extraer, mediante la misma API de IA, la lista de menciones a libros, podcasts, música o artículos presentes en el contenido del artículo. Cada mención SHALL tener al menos su tipo (libro, podcast, música o artículo) y su nombre tal como aparece o se infiere del artículo; una mención de tipo artículo SHALL además incluir la URL detectada. El sistema NO SHALL detectar ni extraer menciones de ningún otro tipo (ej. productos, personas, empresas) en esta versión.

Para que la API de IA pueda identificar semánticamente qué links del artículo corresponden a otro artículo mencionado/citado (a diferencia de links de navegación, redes sociales, o llamadas a la acción), el contenido enviado a la API de IA SHALL preservar los links del artículo (texto del link + URL), en vez de convertir el HTML a texto plano sin ningún link, como hace hoy `article-summaries`.

#### Scenario: Artículo con menciones detectables

- **WHEN** se genera el resumen de un artículo cuyo contenido menciona al menos un libro, podcast, álbum/canción, o link a otro artículo
- **THEN** el sistema incluye, junto al resumen, la lista de esas menciones con su tipo y nombre (y su URL, si el tipo es artículo)

#### Scenario: Artículo sin menciones detectables

- **WHEN** se genera el resumen de un artículo cuyo contenido no menciona ningún libro, podcast, música, ni link a otro artículo
- **THEN** el sistema persiste el resumen con una lista de menciones vacía, sin error

#### Scenario: Artículo que linkea a otro artículo

- **WHEN** el contenido de un artículo incluye un link que el modelo identifica como una mención a otro artículo (no un link de navegación, redes sociales, o CTA)
- **THEN** el sistema incluye esa mención con tipo artículo, el nombre inferido, y la URL del link

### Requirement: Enriquecimiento de menciones vía proveedor externo

El sistema SHALL intentar enriquecer cada mención detectada según su tipo: libros vía Google Books, podcasts y música vía iTunes Search, y artículos haciendo un fetch a la URL detectada para extraer su metadata Open Graph (`og:title`, `og:image`). Para podcast/música, el sistema obtiene una imagen de portada y un link cuando el proveedor encuentra un resultado que matchea el nombre de la mención. Para libros, el sistema obtiene una imagen de portada cuando Google Books encuentra un resultado que matchea el nombre de la mención, pero el link SHALL construirse siempre a partir del nombre de la mención (una URL de búsqueda de Amazon), sin depender de si Google Books encontró match ni de qué campos trajo ese resultado. El sistema SHALL exponer este enriquecimiento detrás de una abstracción genérica reemplazable/ampliable por proveedor, de forma que agregar o cambiar un proveedor (ej. sumar Spotify) no requiera cambios en cómo se detectan ni se muestran las menciones.

El enriquecimiento SHALL ejecutarse contra un proxy propio del sistema (no llamando a los proveedores externos ni a la URL del artículo mencionado directo desde el dispositivo), y NO SHALL descontar del presupuesto diario de palabras de `ai-usage-budget` (no invoca a la API de IA).

Cuando el fetch de Open Graph de una mención de tipo artículo tiene éxito, el `og:title` obtenido SHALL reemplazar el nombre que había inferido la API de IA como nombre mostrado de esa mención.

#### Scenario: Mención enriquecida exitosamente

- **WHEN** el proveedor correspondiente al tipo de una mención encuentra un resultado que matchea su nombre (podcast/música), o el fetch de Open Graph de una mención de tipo artículo tiene éxito
- **THEN** el sistema asocia a esa mención la imagen de portada y el link devueltos por el proveedor; si es de tipo artículo, además reemplaza el nombre por el `og:title` obtenido

#### Scenario: Mención de libro siempre tiene link, con o sin match en Google Books

- **WHEN** se enriquece una mención de tipo libro, independientemente de si Google Books encuentra un resultado que matchee su nombre
- **THEN** el sistema le asocia un link de búsqueda de Amazon construido a partir del nombre de la mención, y le asocia además la imagen de portada de Google Books si hubo match

#### Scenario: Mención de podcast o música sin match del proveedor se muestra igual

- **WHEN** el proveedor correspondiente no encuentra ningún resultado que matchee el nombre de una mención de tipo podcast o música
- **THEN** el sistema conserva esa mención en la lista, mostrándola como texto plano (tipo y nombre) sin imagen ni link, en vez de descartarla

#### Scenario: Falla el proveedor de enriquecimiento de podcast o música

- **WHEN** la consulta al proveedor externo de una mención de tipo podcast o música falla (red, servicio caído, etc.)
- **THEN** el sistema muestra esa mención igual que un caso sin match (texto plano, sin imagen ni link), sin que la falla de un proveedor bloquee la presentación del resumen ni de las demás menciones

#### Scenario: Falla la consulta a Google Books de una mención de libro

- **WHEN** la consulta a Google Books de una mención de tipo libro falla (red, servicio caído, etc.) o no encuentra match
- **THEN** el sistema conserva la mención sin imagen de portada, pero igual le asocia el link de búsqueda de Amazon construido a partir del nombre

#### Scenario: Falla el fetch de Open Graph de una mención de tipo artículo

- **WHEN** el fetch a la URL de una mención de tipo artículo falla, tarda demasiado, o la página no expone `og:title`/`og:image`
- **THEN** el sistema conserva la mención con el nombre que había inferido la API de IA y la URL original detectada, sin imagen, sin que esta falla bloquee la presentación del resumen ni de las demás menciones

### Requirement: Presentación e interacción con menciones en el bottom sheet

El sistema SHALL mostrar, en el mismo bottom sheet donde se presenta el resumen del artículo, una card por cada mención detectada. Las menciones enriquecidas SHALL mostrar su imagen de portada; las de tipo podcast/música no enriquecidas (sin match o con proveedor fallido) SHALL mostrarse como texto plano, sin imagen ni link. Las menciones de tipo libro SHALL ser siempre tappables, con o sin imagen de portada, dado que siempre tienen un link de búsqueda de Amazon asociado.

Tocar una card de mención con link SHALL abrir ese link en el navegador del sistema (no en el `ArticleWebView` interno de la app). Tocar una mención de tipo podcast/música sin enriquecer NO SHALL disparar ninguna navegación.

Una mención de tipo artículo SHALL ser siempre tappable, con o sin imagen: a diferencia de podcast/música (donde la ausencia de link depende de si el proveedor encontró un match por nombre), la URL de una mención de tipo artículo se extrae directamente del contenido del artículo, no de una búsqueda por nombre, así que siempre hay un link real para abrir aunque el fetch de Open Graph no haya conseguido imagen/título.

#### Scenario: Tocar una mención enriquecida abre el navegador del sistema

- **WHEN** el usuario toca una card de mención que tiene link asociado
- **THEN** el sistema abre ese link en el navegador del sistema, no en un WebView dentro de la app

#### Scenario: Tocar una mención de libro sin portada igual abre el link de Amazon

- **WHEN** el usuario toca una card de mención de tipo libro cuya consulta a Google Books no encontró match (sin imagen de portada)
- **THEN** el sistema abre igual el link de búsqueda de Amazon en el navegador del sistema

#### Scenario: Tocar una mención de podcast o música sin enriquecer no hace nada

- **WHEN** el usuario toca una card de mención de tipo podcast o música sin imagen ni link asociados
- **THEN** el sistema no dispara ninguna navegación ni acción

#### Scenario: Tocar una mención de artículo sin imagen igual abre el link

- **WHEN** el usuario toca una card de mención de tipo artículo cuyo fetch de Open Graph falló (sin imagen ni título reemplazado)
- **THEN** el sistema abre igual la URL original detectada en el navegador del sistema

### Requirement: Enriquecimiento sin restricción de suscripción

El enriquecimiento de menciones (requirement "Enriquecimiento de menciones vía proveedor externo") SHALL requerir únicamente una sesión de usuario autenticada, sin exigir suscripción activa. El control de acceso relevante ocurre en `article-summaries` (donde se detectan las menciones raw y se descuenta el límite diario correspondiente); para cuando se solicita el enriquecimiento, el resumen y las menciones ya se generaron dentro de ese límite. Como el enriquecimiento no invoca a la API de IA ni descuenta ningún presupuesto (ver requirement "Enriquecimiento de menciones vía proveedor externo"), no hay costo que justifique limitándolo a usuarios con suscripción activa.

#### Scenario: Usuario sin suscripción activa recibe enriquecimiento completo

- **WHEN** un usuario autenticado sin suscripción activa, dentro de su cupo diario gratis de `article-summaries`, genera el resumen de un artículo con menciones detectadas
- **THEN** el sistema enriquece esas menciones igual que a un usuario con suscripción activa (portadas de libro/podcast/música, Open Graph de artículos), sin degradar el resultado por falta de suscripción

#### Scenario: Solicitud de enriquecimiento sin sesión autenticada

- **WHEN** una solicitud de enriquecimiento de menciones no incluye un token que corresponda a una sesión de usuario autenticada
- **THEN** el sistema la rechaza con un error de autenticación, sin consultar a ningún proveedor externo
