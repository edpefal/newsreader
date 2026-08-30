## MODIFIED Requirements

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
