## MODIFIED Requirements

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

El sistema SHALL intentar enriquecer cada mención detectada según su tipo: libros vía Google Books, podcasts y música vía iTunes Search, y artículos haciendo un fetch a la URL detectada para extraer su metadata Open Graph (`og:title`, `og:image`). Para libro/podcast/música, el sistema obtiene una imagen de portada y un link cuando el proveedor encuentra un resultado que matchea el nombre de la mención. El sistema SHALL exponer este enriquecimiento detrás de una abstracción genérica reemplazable/ampliable por proveedor, de forma que agregar o cambiar un proveedor (ej. sumar Spotify) no requiera cambios en cómo se detectan ni se muestran las menciones.

El enriquecimiento SHALL ejecutarse contra un proxy propio del sistema (no llamando a los proveedores externos ni a la URL del artículo mencionado directo desde el dispositivo), y NO SHALL descontar del presupuesto diario de palabras de `ai-usage-budget` (no invoca a la API de IA).

Cuando el fetch de Open Graph de una mención de tipo artículo tiene éxito, el `og:title` obtenido SHALL reemplazar el nombre que había inferido la API de IA como nombre mostrado de esa mención.

#### Scenario: Mención enriquecida exitosamente

- **WHEN** el proveedor correspondiente al tipo de una mención encuentra un resultado que matchea su nombre (libro/podcast/música), o el fetch de Open Graph de una mención de tipo artículo tiene éxito
- **THEN** el sistema asocia a esa mención la imagen de portada y el link devueltos por el proveedor; si es de tipo artículo, además reemplaza el nombre por el `og:title` obtenido

#### Scenario: Mención sin match del proveedor se muestra igual

- **WHEN** el proveedor correspondiente no encuentra ningún resultado que matchee el nombre de una mención de tipo libro, podcast o música
- **THEN** el sistema conserva esa mención en la lista, mostrándola como texto plano (tipo y nombre) sin imagen ni link, en vez de descartarla

#### Scenario: Falla el proveedor de enriquecimiento

- **WHEN** la consulta al proveedor externo de una mención de tipo libro, podcast o música falla (red, servicio caído, etc.)
- **THEN** el sistema muestra esa mención igual que un caso sin match (texto plano, sin imagen ni link), sin que la falla de un proveedor bloquee la presentación del resumen ni de las demás menciones

#### Scenario: Falla el fetch de Open Graph de una mención de tipo artículo

- **WHEN** el fetch a la URL de una mención de tipo artículo falla, tarda demasiado, o la página no expone `og:title`/`og:image`
- **THEN** el sistema conserva la mención con el nombre que había inferido la API de IA y la URL original detectada, sin imagen, sin que esta falla bloquee la presentación del resumen ni de las demás menciones

### Requirement: Presentación e interacción con menciones en el bottom sheet

El sistema SHALL mostrar, en el mismo bottom sheet donde se presenta el resumen del artículo, una card por cada mención detectada. Las menciones enriquecidas SHALL mostrar su imagen de portada; las de tipo libro/podcast/música no enriquecidas (sin match o con proveedor fallido) SHALL mostrarse como texto plano, sin imagen ni link.

Tocar una card de mención enriquecida SHALL abrir su link en el navegador del sistema (no en el `ArticleWebView` interno de la app). Tocar una mención de tipo libro/podcast/música sin enriquecer NO SHALL disparar ninguna navegación.

Una mención de tipo artículo SHALL ser siempre tappable, con o sin imagen: a diferencia de libro/podcast/música (donde la ausencia de link depende de si el proveedor encontró un match por nombre), la URL de una mención de tipo artículo se extrae directamente del contenido del artículo, no de una búsqueda por nombre, así que siempre hay un link real para abrir aunque el fetch de Open Graph no haya conseguido imagen/título.

#### Scenario: Tocar una mención enriquecida abre el navegador del sistema

- **WHEN** el usuario toca una card de mención que tiene imagen y link asociados
- **THEN** el sistema abre ese link en el navegador del sistema, no en un WebView dentro de la app

#### Scenario: Tocar una mención de libro/podcast/música sin enriquecer no hace nada

- **WHEN** el usuario toca una card de mención de tipo libro, podcast o música sin imagen ni link asociados
- **THEN** el sistema no dispara ninguna navegación ni acción

#### Scenario: Tocar una mención de artículo sin imagen igual abre el link

- **WHEN** el usuario toca una card de mención de tipo artículo cuyo fetch de Open Graph falló (sin imagen ni título reemplazado)
- **THEN** el sistema abre igual la URL original detectada en el navegador del sistema
