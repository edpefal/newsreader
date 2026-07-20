# Spec: Daily Summaries

## Purpose

Define cómo el sistema genera, almacena y presenta resúmenes diarios de los artículos del inbox usando una API de IA en la nube. Cada día tiene como máximo un resumen, que puede regenerarse a partir de los artículos publicados ese día.

## Requirements

### Requirement: Generación de resumen diario del inbox
El sistema SHALL generar, mediante una API de IA en la nube, un resumen de texto agrupado por fuente a partir del título y el contenido de los artículos del inbox (no leídos, no archivados) cuyo `publishedAt` corresponde a la fecha actual. Para cada artículo, el contenido usado SHALL ser el texto plano extraído de `contentHtml` cuando el artículo tiene contenido completo (no truncado); si `contentHtml` está truncado o vacío, SHALL usarse `excerpt` como fallback.

#### Scenario: Generar resumen con artículos disponibles
- **WHEN** el usuario toca "Crear resumen" y el inbox tiene al menos un artículo publicado hoy
- **THEN** el sistema agrupa esos artículos por fuente, genera un párrafo por cada fuente (prefijado con su nombre) invocando la API de IA, y al finalizar crea o actualiza el `DailySummary` del día de hoy con el texto combinado

#### Scenario: Artículo con contenido completo usa el texto extraído de contentHtml
- **WHEN** un artículo del inbox de hoy tiene `contentHtml` no truncado (mismo criterio que `FeedContentChecker.isTruncated`)
- **THEN** el sistema usa el texto plano extraído de `contentHtml` (sin tags HTML) como contenido de ese artículo en el resumen, sin límite de longitud

#### Scenario: Artículo con contenido truncado usa excerpt como fallback
- **WHEN** un artículo del inbox de hoy tiene `contentHtml` truncado o vacío (mismo criterio que `FeedContentChecker.isTruncated`)
- **THEN** el sistema usa `excerpt` como contenido de ese artículo en el resumen, igual que el comportamiento anterior

#### Scenario: Botón deshabilitado sin artículos de hoy
- **WHEN** el inbox no tiene artículos con `publishedAt` de la fecha actual
- **THEN** el botón "Crear resumen" SHALL estar deshabilitado y no SHALL invocarse la API de IA

#### Scenario: Falla la generación del resumen
- **WHEN** la llamada a la API de IA falla (sin red, error del backend, respuesta inválida, etc.)
- **THEN** el sistema SHALL mostrar un estado de error distinguible del estado "sin artículos", permitiendo reintentar

### Requirement: Sobrescritura del resumen del día actual
El sistema SHALL mantener como máximo un `DailySummary` por fecha. Generar un nuevo resumen para el día actual SHALL reemplazar el resumen existente de ese mismo día.

#### Scenario: Regenerar el resumen de hoy
- **WHEN** ya existe un `DailySummary` para la fecha de hoy y el usuario toca "Regenerar"
- **THEN** el sistema sobrescribe el contenido y `articleCount` del `DailySummary` existente de hoy, sin crear un segundo item para la misma fecha

#### Scenario: Nuevo día crea un nuevo resumen
- **WHEN** el usuario genera un resumen en una fecha distinta a la de cualquier `DailySummary` existente
- **THEN** el sistema crea un nuevo `DailySummary` para esa fecha, dejando intactos los resúmenes de días anteriores

### Requirement: Listado de resúmenes diarios
El sistema SHALL mostrar una pantalla con la lista de todos los `DailySummary` existentes, ordenados de más reciente a más antiguo, cada uno mostrando la fecha y la cantidad de artículos resumidos.

#### Scenario: Lista vacía en primer ingreso
- **WHEN** el usuario entra a la pantalla de Resúmenes y no existe ningún `DailySummary`
- **THEN** el sistema muestra únicamente el botón para crear el resumen de hoy, sin items en la lista

#### Scenario: Lista con resúmenes existentes
- **WHEN** existen uno o más `DailySummary`
- **THEN** el sistema los lista ordenados por fecha descendente, mostrando el botón de regenerar asociado al día de hoy

### Requirement: Detalle de un resumen
El sistema SHALL permitir ver el texto completo de un `DailySummary` al seleccionar su item en la lista.

#### Scenario: Ver detalle de un resumen
- **WHEN** el usuario toca un item de la lista de resúmenes
- **THEN** el sistema navega a una pantalla de detalle que muestra el texto completo, la fecha y la cantidad de artículos de ese resumen
