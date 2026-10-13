## Context

La tab Resúmenes es hoy un master-detail como las demás: `SummariesScreen` pinta un `ListView` de `SummaryListItem`, el detalle vive en `/summaries/:date` (`SummaryDetailScreen`, con su propio `Scaffold`/`AppBar`) y el lector se anida en `/summaries/:date/article/:articleId`. Ver proposal.md para la motivación.

Puntos del código que condicionan el enfoque:

- `_adaptiveBranchShell` (router.dart) arma `AdaptiveListDetailScaffold(list: SummariesScreen, detail: child)` en ≥840dp y devuelve solo `child` en compact. `AdaptiveShell` oculta su AppBar/drawer cuando la ruta activa no está en `branchRootPaths` (compact con detalle empujado).
- `SummaryDetailScreen` también se usa en la ruta del Inbox (`/summary/:id`), con `onOpened` = `DismissDailySummary`.
- `DismissDailySummary` ya ignora resúmenes que no son de hoy (`isLocalToday`), así que abrir la tab con un resumen viejo no escribe nada.
- `HiveSummaryDatasource.getAll()` ya devuelve los resúmenes ordenados por fecha descendente.
- `AdaptiveListDetailScaffold` fija el panel izquierdo en 380pt por defecto.

## Goals / Non-Goals

**Goals:**
- La raíz de la tab muestra el último `DailySummary` (o el estado vacío) sin pasar por una lista.
- Sin AppBar duplicado en compact ni en expanded.
- Mantener el master-detail en iPad (resumen a la izquierda, lector a la derecha) y la persistencia de selección al cruzar 840dp.

**Non-Goals:**
- Cambios de servidor, esquema, sincronización o retención de datos: los resúmenes viejos no se borran, solo dejan de mostrarse.
- Cambiar la tarjeta del Inbox ni su ruta `/summary/:id`.
- Un acceso alternativo al historial (decidido: dejan de ser accesibles).

## Decisions

### 1. Cuerpo del detalle extraído a un widget sin `Scaffold`

Se extrae el `SingleChildScrollView` de `SummaryDetailScreen` a un widget `SummaryDetailBody` (mismo feature, un archivo) que recibe el `DailySummary` y los use cases de resolución, y que muestra la fecha larga como primer elemento del contenido. `SummaryDetailScreen` pasa a ser `Scaffold` + `AppBar` + `SummaryDetailBody`, y se sigue usando solo en la ruta del Inbox.

La raíz de la tab usa `SummaryDetailBody` directamente: compact queda bajo el AppBar del shell y en iPad dentro del panel izquierdo, sin chrome duplicado (regla de CLAUDE.md para pantallas embebibles).

*Alternativa descartada:* un flag `showAppBar` en `SummaryDetailScreen`. Mezcla dos presentaciones en un widget y deja un `Scaffold` anidado dentro del body del shell; extraer el cuerpo es más simple y testeable.

### 2. `onOpened` se mantiene: abrir la tab descarta la tarjeta de hoy

Se conserva el comportamiento actual (spec `inbox-daily-summary-card`: "al mostrarse el detalle del resumen de hoy, desde la tarjeta o desde la tab Resúmenes… persistir `dismissed_at`"). `SummaryDetailBody` recibe `onOpened` y lo invoca una vez al montarse, igual que hoy; la raíz de la tab pasa `DismissDailySummary.execute(summary.id)`.

Razón: es lo que el usuario ya entiende hoy (ver el resumen = ya lo vio) y evita una tarjeta en el Inbox de algo que está a la vista en la tab. Para un resumen de un día anterior no pasa nada, porque `DismissDailySummary` lo ignora.

Efecto a vigilar: como la tab es ahora el destino por defecto del último resumen, basta con *entrar* a la tab (aunque no se lea) para descartar la tarjeta. Es el mismo criterio que ya aplicaba al abrir el detalle, solo con un toque menos. No se introduce una condición de scroll o tiempo de lectura.

### 3. Cubit y use case

`GetDailySummaries` se reemplaza por `GetLatestDailySummary` (`Future<DailySummary?>`), que toma `getAll().first` apoyándose en el orden descendente ya garantizado por el datasource (y cubierto por un test del use case, para no depender de él implícitamente). `SummariesLoaded` pasa a llevar `DailySummary? summary` (`null` = estado vacío). Esto mantiene la lógica fuera del Cubit (regla de CLAUDE.md) y deja de cargar la lista completa en memoria solo para descartarla.

*Alternativa descartada:* filtrar en el Cubit con `summaries.first`. Mueve una regla de negocio ("solo el último") a presentación.

### 4. Rutas

```
/summaries                        raíz: resumen más reciente / vacío
/summaries/article/:articleId     lector (+ /web)
```

Se elimina `/summaries/:date`. `/summaries` en expanded sigue sirviendo el placeholder en el panel derecho (reescrito a "elige un artículo"); el panel izquierdo lo arma `_adaptiveBranchShell` con la nueva `SummariesScreen` (el cuerpo del resumen). En compact, `/summaries` construye `SummariesScreen` y `/summaries/article/:articleId` se empuja a pantalla completa; `branchRootPaths` no cambia (`/summaries` sigue siendo la raíz).

Una URL `/summaries/<fecha>` ya no coincide con ninguna ruta y `go_router` la trata como no encontrada. Se confirma en las tareas qué muestra hoy la app en ese caso (`errorBuilder`/redirect) y que no es una pantalla en blanco.

### 5. Ancho del panel izquierdo en iPad

El resumen con tarjetas por fuente y filas con miniatura es más ancho que una fila de lista; 380pt resulta justo. `AdaptiveListDetailScaffold` ya expone `listWidth`: para Resúmenes se pasa un valor mayor (a fijar al implementar, partiendo de ~480pt) para que las tarjetas no se aprieten. El tope de contenido de ~680pt se mantiene.

## Risks / Trade-offs

- [Pérdida de acceso a resúmenes viejos, intencional] → Los datos siguen en Hive y Supabase; recuperar el historial después solo requiere UI.
- [Descartar la tarjeta solo por entrar a la tab] → Mismo criterio que hoy; documentado en la decisión 2.
- [Deep links o estado restaurado apuntando a `/summaries/:date` o `/summaries/:date/article/:id`] → Ya no coinciden con una ruta; se cubre con una prueba de que la app cae en una ruta válida en vez de un error. Las URLs viejas no son externas (la app no publica deep links), así que el único riesgo es el estado de navegación restaurado de una versión anterior.
- [Panel izquierdo de 380pt apretado] → `listWidth` mayor solo para Resúmenes (decisión 5).
- [Archivar con RENAMED + MODIFIED del requirement "Listado de resúmenes diarios"] → Si el CLI se niega, aplicar la fusión a mano como indica CLAUDE.md (`--skip-specs`).

## Migration Plan

Solo cliente, sin migración de datos ni despliegue de servidor. Rollback: revertir el PR; los resúmenes siguen intactos.
