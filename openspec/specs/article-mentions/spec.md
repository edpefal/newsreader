# Spec: Article Mentions

## Purpose

Define cómo el sistema detecta menciones a libros, podcasts y música dentro de un artículo, cómo las enriquece con datos de proveedores externos (portada e link), y cómo se presentan y comportan en la UI, incluyendo el caso en que no se encuentra un match.

## Requirements

### Requirement: Detección de menciones al generar el resumen de un artículo

Al generar el resumen de un artículo (capability `article-summaries`), el sistema SHALL además extraer, mediante la misma API de IA, la lista de menciones a libros, podcasts o música presentes en el contenido del artículo, cada una con al menos su tipo (libro, podcast o música) y su nombre tal como aparece o se infiere del artículo. El sistema NO SHALL detectar ni extraer menciones de ningún otro tipo (ej. productos, personas, empresas) en esta versión.

#### Scenario: Artículo con menciones detectables

- **WHEN** se genera el resumen de un artículo cuyo contenido menciona al menos un libro, podcast o álbum/canción
- **THEN** el sistema incluye, junto al resumen, la lista de esas menciones con su tipo y nombre

#### Scenario: Artículo sin menciones detectables

- **WHEN** se genera el resumen de un artículo cuyo contenido no menciona ningún libro, podcast o música
- **THEN** el sistema persiste el resumen con una lista de menciones vacía, sin error

### Requirement: Enriquecimiento de menciones vía proveedor externo

El sistema SHALL intentar enriquecer cada mención detectada consultando un proveedor externo según su tipo (libros vía Google Books, podcasts y música vía iTunes Search), obteniendo una imagen de portada y un link cuando el proveedor encuentra un resultado que matchea el nombre de la mención. El sistema SHALL exponer este enriquecimiento detrás de una abstracción genérica reemplazable/ampliable por proveedor, de forma que agregar o cambiar un proveedor (ej. sumar Spotify) no requiera cambios en cómo se detectan ni se muestran las menciones.

El enriquecimiento SHALL ejecutarse contra un proxy propio del sistema (no llamando a los proveedores externos directo desde el dispositivo), y NO SHALL descontar del presupuesto diario de palabras de `ai-usage-budget` (no invoca a la API de IA).

#### Scenario: Mención enriquecida exitosamente

- **WHEN** el proveedor correspondiente al tipo de una mención encuentra un resultado que matchea su nombre
- **THEN** el sistema asocia a esa mención la imagen de portada y el link devueltos por el proveedor

#### Scenario: Mención sin match del proveedor se muestra igual

- **WHEN** el proveedor correspondiente no encuentra ningún resultado que matchee el nombre de una mención
- **THEN** el sistema conserva esa mención en la lista, mostrándola como texto plano (tipo y nombre) sin imagen ni link, en vez de descartarla

#### Scenario: Falla el proveedor de enriquecimiento

- **WHEN** la consulta al proveedor externo de una mención falla (red, servicio caído, etc.)
- **THEN** el sistema muestra esa mención igual que un caso sin match (texto plano, sin imagen ni link), sin que la falla de un proveedor bloquee la presentación del resumen ni de las demás menciones

### Requirement: Presentación e interacción con menciones en el bottom sheet

El sistema SHALL mostrar, en el mismo bottom sheet donde se presenta el resumen del artículo, una card por cada mención detectada. Las menciones enriquecidas SHALL mostrar su imagen de portada; las no enriquecidas (sin match o con proveedor fallido) SHALL mostrarse como texto plano, sin imagen ni link.

Tocar una card de mención enriquecida SHALL abrir su link en el navegador del sistema (no en el `ArticleWebView` interno de la app). Tocar una mención sin enriquecer NO SHALL disparar ninguna navegación.

#### Scenario: Tocar una mención enriquecida abre el navegador del sistema

- **WHEN** el usuario toca una card de mención que tiene imagen y link asociados
- **THEN** el sistema abre ese link en el navegador del sistema, no en un WebView dentro de la app

#### Scenario: Tocar una mención sin enriquecer no hace nada

- **WHEN** el usuario toca una card de mención sin imagen ni link asociados
- **THEN** el sistema no dispara ninguna navegación ni acción
